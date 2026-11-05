import os
import re
import xml.etree.ElementTree as ET
import subprocess
import numpy as np
import random
import soundfile as sf
from kokoro import KPipeline
from pydub import AudioSegment
from pydub.generators import Sine, WhiteNoise

# Configuration de la voix Kokoro (Anglais américain 'a') :
# - 'am_fenrir' : Voix masculine grave, rauque, éraillée / criarde (style opérateur radio sous tension)
# - 'am_adam'   : Voix masculine grave et autoritaire
# - 'am_onyx'   : Voix masculine très profonde et lourde
KOKORO_LANG = "a"
KOKORO_VOICE = "am_fenrir"
KOKORO_SPEED = 1.08  # Débit radio militaire tendu et rythmé

# Initialisation du pipeline Kokoro TTS
_pipeline = KPipeline(lang_code=KOKORO_LANG)

# Ajouter ffmpeg et ffprobe au PATH système pour cette exécution
ffmpeg_bin_path = r"C:\Users\kevin\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.1-full_build\bin"
os.environ["PATH"] += os.pathsep + ffmpeg_bin_path

AudioSegment.converter = os.path.join(ffmpeg_bin_path, "ffmpeg.exe")


# Chemin vers la racine du projet
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
XML_PATH = os.path.join(ROOT_DIR, "stringtable.xml")
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
FORCE_REGENERATE = True  # Mettre à True pour écraser et régénérer tous les fichiers avec Kokoro

def clean_text(text):
    if not text:
        return ""
    
    # Ignorer complètement les actions
    if "<t color" in text or text.startswith("["):
        return ""
        
    # Le texte %1 et tout ce qu'il y a après ne doit pas être récupéré
    text = re.split(r"%\d+", text)[0]
    
    text = re.sub(r"<[^>]+>", "", text)
    
    # Ignorer les textes qui ne contiennent aucune lettre ou chiffre (ex: "...")
    if not re.search(r'[a-zA-Z0-9]', text):
        return ""
    
    return text.strip()

def apply_radio_effect(audio, intensity=1.5):
    # --- VARIATION ALÉATOIRE PAR MESSAGE ---
    # Chaque message est légèrement différent pour éviter l'effet "source unique parfaite"
    rng_gain      = random.uniform(-1.0, 3.0)
    rng_hp        = random.randint(260, 380)
    rng_lp        = random.randint(2300, 3100)
    rng_noise_lvl = random.uniform(-2.0, 2.0)
    rng_clip      = random.uniform(0.24, 0.42)  # Clipping plus agressif pour un son criard / saturé

    # 0. Abaissement du pitch pour une voix d'homme plus grave et martiale
    pitch_factor = 0.93  # Abaissement du timbre
    lower_rate = int(audio.frame_rate * pitch_factor)
    audio = audio._spawn(audio.raw_data, overrides={'frame_rate': lower_rate}).set_frame_rate(audio.frame_rate)

    # 1. Dégradation bit-crushing AVANT normalisation
    radio = audio.set_frame_rate(8000).set_sample_width(1)
    
    # 2. Filtre passe-bande "Radio Militaire" (Double passe agressive avec variation)
    radio = radio.high_pass_filter(rng_hp).low_pass_filter(rng_lp)
    radio = radio.high_pass_filter(rng_hp + 80).low_pass_filter(rng_lp - 200)

    # 3. Saturation + Hard Clipping via numpy (voix criarde / intercom militaire)
    radio = radio.apply_gain(rng_gain + 10)
    samples = np.array(radio.get_array_of_samples(), dtype=np.float32)
    max_val = np.iinfo(radio.array_type).max
    samples /= max_val
    samples = np.clip(samples, -rng_clip, rng_clip)
    samples /= rng_clip
    samples = (samples * max_val * 0.85).astype(radio.array_type)
    radio = radio._spawn(samples.tobytes())

    # 4. Bruit de fond intermittent (Crackle) — NON-uniforme
    dur_ms  = len(radio)
    crackle = AudioSegment.silent(duration=dur_ms)
    t = 0
    while t < dur_ms:
        burst_len  = random.randint(8, 40)
        gap        = random.randint(30, 200)
        burst_gain = random.uniform(-22 - (intensity * 2), -16 - (intensity * 2)) + rng_noise_lvl
        burst      = WhiteNoise().to_audio_segment(duration=burst_len).apply_gain(burst_gain)
        crackle    = crackle.overlay(burst, position=t)
        t += burst_len + gap

    static_base = (
        WhiteNoise().to_audio_segment(duration=dur_ms)
        .high_pass_filter(800)
        .apply_gain(-24 - intensity + rng_noise_lvl)
    )
    radio = radio.overlay(static_base).overlay(crackle)

    # 5. Micro-dropouts (coupures brèves simulant une connexion instable)
    samples_out = np.array(radio.get_array_of_samples(), dtype=np.int16)
    num_drops   = random.randint(0, 3)
    for _ in range(num_drops):
        drop_start = random.randint(0, len(samples_out) - 1)
        drop_len   = int(radio.frame_rate * random.uniform(0.005, 0.015))
        end_idx    = min(drop_start + drop_len, len(samples_out))
        samples_out[drop_start:end_idx] = np.int16(np.linspace(
            samples_out[drop_start], 0, end_idx - drop_start
        ))
    radio = radio._spawn(samples_out.tobytes())

    # 6. Pitch Wobble — instabilité légère de vitesse (VCO / bande magnétique usée)
    wobble_rate = int(radio.frame_rate * random.uniform(0.985, 1.015))
    radio = radio.set_frame_rate(wobble_rate).set_frame_rate(radio.frame_rate)

    # 7. Squelch amélioré — ouverture montante, Roger Beep variable, squelch tail organique
    squelch_noise_in = WhiteNoise().to_audio_segment(duration=30).apply_gain(-6)
    squelch_click_in = WhiteNoise().to_audio_segment(duration=15).apply_gain(-14)
    squelch_in       = squelch_noise_in + squelch_click_in

    beep_freq    = random.randint(1150, 1250)
    beep1        = Sine(beep_freq).to_audio_segment(45).apply_gain(-9)
    gap_beep     = AudioSegment.silent(duration=random.randint(15, 25))
    beep2        = Sine(beep_freq + random.randint(-30, 30)).to_audio_segment(45).apply_gain(-11)
    squelch_tail = (
        WhiteNoise().to_audio_segment(duration=120)
        .high_pass_filter(1500)
        .apply_gain(-10)
        .fade_out(100)
    )
    squelch_out = beep1 + gap_beep + beep2 + squelch_tail

    final = squelch_in + radio + squelch_out

    # 8. Normalisation légère à -3dBFS (préserve la dégradation organique)
    headroom_db = 3
    peak = final.max_dBFS
    if peak > -headroom_db:
        final = final.apply_gain(-headroom_db - peak)

    final = final.set_frame_rate(44100).set_sample_width(2)
    return final


def generate_tts(text, output_path, key_id="", speed=KOKORO_SPEED, voice=KOKORO_VOICE):
    chunks = [a for _, _, a in _pipeline(text, voice=voice, speed=speed)]
    sf.write(output_path, np.concatenate(chunks), 24000)  # sortie en .wav

def generate_cfg_sounds(output_dir, cfg_path):
    sounds = []
    for file in os.listdir(output_dir):
        if file.endswith(".ogg"):
            sounds.append(file[:-4])
            
    with open(cfg_path, "w", encoding="utf-8") as f:
        f.write('class CfgSounds\n{\n    sounds[] = {};\n\n')
        for key_id in sorted(sounds):
            f.write(f'    class {key_id}\n    {{\n')
            f.write(f'        name = "{key_id}";\n')
            f.write(f'        sound[] = {{"TTS\\output\\{key_id}.ogg", db+5, 1.0}};\n')
            f.write(f'        titles[] = {{0, ""}};\n')
            f.write(f'    }};\n')
        f.write('    class LL_Charge_Beep\n    {\n        name = "LL_Charge_Beep";\n        sound[] = {"A3\\Sounds_F\\sfx\\beep_target.wss", db+8, 1.0};\n        titles[] = {0, ""};\n    };\n')
        f.write('    class Sound_Music_Intro\n    {\n        name = "Sound_Music_Intro";\n        sound[] = {"Music\\Shadow_of_the_Valley_01.ogg", db+0, 1.0};\n        titles[] = {0, ""};\n    };\n')
        f.write('    class ezan\n    {\n        name = "ezan";\n        sound[] = {"Music\\ezan.ogg", db+12, 1.0, 2000};\n        titles[] = {0, ""};\n    };\n')
        f.write('};\n')
    print(f"[CfgSounds] Généré avec succès ({len(sounds)} sons) dans {cfg_path}")

def is_tts_key(key_id):
    # Clés liées aux messages radio et PNJ
    prefixes = ("STR_Drone_", "STR_LL_Heli_", "STR_LL_Msg_", "STR_TAG_Msg_", "STR_LL_Radio_")
    if key_id.startswith(prefixes):
        return True
    # Clés liées aux dialogues (STR_LL_Task_XX_S1, etc.)
    if re.search(r"STR_LL_Task_.*_S\d+", key_id):
        return True
    # Clés spécifiques de la liste précédente
    specific_keys = {
        "STR_LL_AssignLeader_Changed", "STR_LL_HealAction_Healing", 
        "STR_LL_HealAction_NoKits", "STR_LL_HealAction_NoWounded", 
        "STR_LL_RoeAction_Changed", "STR_LL_Task_Assigned", "STR_LL_Task_05_Alert"
    }
    return key_id in specific_keys

def main():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    tree = ET.parse(XML_PATH)
    root = tree.getroot()
    
    count = 0
    temp_file = os.path.join(OUTPUT_DIR, "temp.wav")
    
    for key in root.findall(".//Key"):
        key_id = key.get("ID")
        
        if not is_tts_key(key_id):
            continue
            
        # Utilisation de la version anglaise (voix d'homme en anglais)
        node = key.find("English")
        if node is None or not node.text:
            node = key.find("Original")
        
        if node is not None and node.text:
            text = clean_text(node.text)
            
            if not text:
                continue
                
            out_file = os.path.join(OUTPUT_DIR, f"{key_id}.ogg")
            
            # Skip if file already exists (sauf si FORCE_REGENERATE est activé)
            if os.path.exists(out_file) and not FORCE_REGENERATE:
                continue
                
            print(f"[TTS] Génération Kokoro pour {key_id} : '{text}'")
            
            try:
                # 1. Générer le TTS avec Kokoro (format .wav)
                generate_tts(text, temp_file, key_id=key_id)
                
                # 2. Charger le .wav et appliquer les effets radio militaires
                audio = AudioSegment.from_wav(temp_file)
                radio_audio = apply_radio_effect(audio)
                
                # 3. Sauvegarder en OGG (format Arma 3)
                radio_audio.export(out_file, format="ogg")
                count += 1
                
            except Exception as e:
                print(f"Erreur sur {key_id} : {e}")
                
    if os.path.exists(temp_file):
        try:
            os.remove(temp_file)
        except:
            pass
            
    print(f"\nTerminé ! {count} nouveaux fichiers audio générés dans {OUTPUT_DIR}")
    
    # Génération automatique de CfgSounds.hpp
    cfg_path = os.path.join(ROOT_DIR, "CfgSounds.hpp")
    generate_cfg_sounds(OUTPUT_DIR, cfg_path)

if __name__ == "__main__":
    main()
