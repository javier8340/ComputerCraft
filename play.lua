-- play.lua
-- Reproduce archivos DFPWM locales o desde una URL

local input = ...

if not input then
    print("Uso:")
    print("  play <archivo.dfpwm>")
    print("  play <URL>")
    return
end

-- Buscar speaker
local speaker = peripheral.find("speaker")

if not speaker then
    print("ERROR: no se ha encontrado un speaker.")
    return
end

-- Cargar decoder DFPWM
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

local source

-- ============================================================
-- ABRIR FUENTE
-- ============================================================

if input:match("^https?://") then
    print("Descargando:")
    print(input)

    local response, err = http.get(input)

    if not response then
        print("ERROR al abrir URL:")
        print(tostring(err))
        return
    end

    source = response
else
    print("Archivo:")
    print(input)

    if not fs.exists(input) then
        print("ERROR: el archivo no existe.")
        return
    end

    source = fs.open(input, "rb")

    if not source then
        print("ERROR: no se pudo abrir el archivo.")
        return
    end
end

-- ============================================================
-- REPRODUCCIÓN
-- ============================================================

print("Reproduciendo...")

while true do
    -- 16 KiB de DFPWM = hasta 131072 muestras PCM
    -- que es el máximo que acepta el speaker.
    local chunk = source.read(16 * 1024)

    if not chunk then
        break
    end

    -- IMPORTANTE:
    -- decoder() devuelve UNA tabla de muestras PCM.
    local buffer = decoder(chunk)

    -- Esperar hasta que el speaker pueda aceptar el buffer
    while not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
    end
end

-- ============================================================
-- CERRAR
-- ============================================================

source.close()

print("Reproducción terminada.")