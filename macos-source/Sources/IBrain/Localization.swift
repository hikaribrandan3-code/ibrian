// Simple translation system for iBrain (English + Spanish + Portuguese).
import Foundation

enum Language: String, CaseIterable, Identifiable {
    case en = "English"
    case es = "Español"
    case pt = "Português"

    var id: String { rawValue }
}

struct Strings {
    static func get(_ key: String, lang: Language) -> String {
        let table: [String: [Language: String]] = [
            "sidebar.newChat": [.en: "New chat", .es: "Nuevo chat", .pt: "Novo chat"],
            "sidebar.search": [.en: "Search chats...", .es: "Buscar chats...", .pt: "Pesquisar chats..."],
            "sidebar.settings": [.en: "Settings", .es: "Ajustes", .pt: "Configurações"],
            "sidebar.today": [.en: "TODAY", .es: "HOY", .pt: "HOJE"],
            "sidebar.yesterday": [.en: "YESTERDAY", .es: "AYER", .pt: "ONTEM"],
            "sidebar.previous": [.en: "PREVIOUS", .es: "ANTERIOR", .pt: "ANTERIOR"],
            "sidebar.noChats": [.en: "No chats yet", .es: "Aún no hay chats", .pt: "Ainda não há chats"],

            "chat.local": [.en: "Local", .es: "Local", .pt: "Local"],
            "chat.placeholder": [.en: "Ask iBrain anything...", .es: "Pregúntale a iBrain...", .pt: "Pergunte ao iBrain..."],
            "chat.thinking": [.en: "Thinking...", .es: "Pensando...", .pt: "Pensando..."],
            "chat.stop": [.en: "Stop", .es: "Detener", .pt: "Parar"],
            "chat.copy": [.en: "Copy", .es: "Copiar", .pt: "Copiar"],
            "chat.copied": [.en: "Copied", .es: "Copiado", .pt: "Copiado"],
            "chat.newTitle": [.en: "New chat", .es: "Nuevo chat", .pt: "Novo chat"],
            "chat.error": [
                .en: "Could not reach the selected model. Check Ollama or your cloud provider and try again.",
                .es: "No se pudo conectar con el modelo. Verifica Ollama o tu proveedor en la nube e intenta de nuevo.",
                .pt: "Não foi possível acessar o modelo. Verifique o Ollama ou seu provedor de nuvem e tente novamente.",
            ],

            "welcome.title": [.en: "Welcome to iBrain", .es: "Bienvenido a iBrain", .pt: "Bem-vindo ao iBrain"],
            "welcome.subtitle": [
                .en: "Local Ollama chat by default. Optional cloud mode sends prompts to the provider you choose.",
                .es: "Chat local con Ollama por defecto. El modo nube opcional envía mensajes al proveedor elegido.",
                .pt: "Chat local com Ollama por padrão. O modo de nuvem opcional envia mensagens ao provedor escolhido.",
            ],
            "welcome.tile.code": [.en: "Write a Python script", .es: "Escribe un script en Python", .pt: "Escreva um script Python"],
            "welcome.tile.ideas": [.en: "Brainstorm ideas", .es: "Lluvia de ideas", .pt: "Brainstore ideias"],
            "welcome.tile.edit": [.en: "Edit and rewrite text", .es: "Edita y reescribe texto", .pt: "Editar e reescrever texto"],
            "welcome.tile.explain": [.en: "Explain a concept", .es: "Explica un concepto", .pt: "Explicar um conceito"],
            "welcome.ready": [.en: "ready", .es: "listo", .pt: "pronto"],

            "welcome.prompt.code": [
                .en: "Write a Python script that renames all files in a folder to lowercase.",
                .es: "Escribe un script en Python que renombre todos los archivos de una carpeta a minúsculas.",
                .pt: "Escreva um script Python que renomeia todos os arquivos em uma pasta para minúsculas.",
            ],
            "welcome.prompt.ideas": [
                .en: "Help me brainstorm 10 creative ideas for ",
                .es: "Ayúdame con una lluvia de 10 ideas creativas para ",
                .pt: "Ajude-me a pensar em 10 ideias criativas para ",
            ],
            "welcome.prompt.edit": [
                .en: "Rewrite this to sound more professional: ",
                .es: "Reescribe esto para que suene más profesional: ",
                .pt: "Reescreva isto para soar mais profissional: ",
            ],
            "welcome.prompt.explain": [
                .en: "Explain in simple terms how ",
                .es: "Explica en términos simples cómo ",
                .pt: "Explique em termos simples como ",
            ],

            "setup.title": [.en: "Ollama isn't running", .es: "Ollama no está funcionando", .pt: "Ollama não está em execução"],
            "setup.subtitle": [
                .en: "iBrain needs Ollama, the free local AI engine, running on your Mac.",
                .es: "iBrain necesita Ollama, el motor de IA local gratuito, funcionando en tu Mac.",
                .pt: "O iBrain precisa do Ollama, o mecanismo de IA local gratuito, em execução no seu Mac.",
            ],
            "setup.notInstalled.title": [.en: "Ollama isn't installed", .es: "Ollama no está instalado", .pt: "Ollama não está instalado"],
            "setup.notInstalled.subtitle": [
                .en: "Install it once with Homebrew, then pull a model:",
                .es: "Instálalo una vez con Homebrew, luego descarga un modelo:",
                .pt: "Instale uma vez com Homebrew, depois baixe um modelo:",
            ],
            "setup.start": [.en: "Start Ollama", .es: "Iniciar Ollama", .pt: "Iniciar Ollama"],
            "setup.retry": [.en: "Check again", .es: "Verificar de nuevo", .pt: "Verificar novamente"],
            "setup.starting": [.en: "Starting...", .es: "Iniciando...", .pt: "Iniciando..."],
            "setup.noModels.title": [.en: "No models installed", .es: "No hay modelos instalados", .pt: "Nenhum modelo instalado"],
            "setup.noModels.subtitle": [
                .en: "Ollama is running but has no models. Pull one in Terminal:",
                .es: "Ollama está funcionando pero no tiene modelos. Descarga uno en la Terminal:",
                .pt: "Ollama está em execução, mas não tem modelos. Baixe um no Terminal:",
            ],
            "setup.noModels.ask": [
                .en: "iBrain needs one AI model to work. Download the recommended free model now?",
                .es: "iBrain necesita un modelo de IA para funcionar. ¿Descargar el modelo gratuito recomendado ahora?",
                .pt: "O iBrain precisa de um modelo de IA para funcionar. Baixar o modelo recomendado gratuito agora?",
            ],
            "setup.noModels.yes": [.en: "Yes, download it", .es: "Sí, descargarlo", .pt: "Sim, baixe"],
            "setup.noModels.no": [.en: "No, I'll do it myself", .es: "No, lo haré yo mismo", .pt: "Não, vou fazer isso"],
            "setup.noModels.failed": [
                .en: "Download didn't finish. You can try again, or pull it manually in Terminal:",
                .es: "La descarga no terminó. Puedes intentarlo de nuevo, o descargarlo manualmente en la Terminal:",
                .pt: "O download não terminou. Você pode tentar novamente ou baixá-lo manualmente no Terminal:",
            ],
            "setup.downloading.title": [.en: "Downloading model...", .es: "Descargando modelo...", .pt: "Baixando modelo..."],
            "setup.downloading.subtitle": [
                .en: "This only happens once. iBrain will be ready right after.",
                .es: "Esto solo pasa una vez. iBrain estará listo justo después.",
                .pt: "Isso só acontece uma vez. O iBrain estará pronto logo depois.",
            ],

            "settings.general": [.en: "GENERAL", .es: "GENERAL", .pt: "GERAL"],
            "settings.model": [.en: "Default model", .es: "Modelo predeterminado", .pt: "Modelo padrão"],
            "settings.language": [.en: "Language", .es: "Idioma", .pt: "Idioma"],
            "settings.appearance": [.en: "Appearance", .es: "Apariencia", .pt: "Aparência"],
            "settings.behavior": [.en: "BEHAVIOR", .es: "COMPORTAMIENTO", .pt: "COMPORTAMENTO"],
            "settings.customAI": [.en: "CUSTOM AI", .es: "IA PERSONALIZADA", .pt: "IA PERSONALIZADA"],
            "settings.customAI.subtitle": [
                .en: "Write your own instructions for how iBrain should respond. Leave blank for the default behavior.",
                .es: "Escribe tus propias instrucciones sobre cómo debe responder iBrain. Déjalo en blanco para el comportamiento predeterminado.",
                .pt: "Escreva suas próprias instruções sobre como o iBrain deve responder. Deixe em branco para o comportamento padrão.",
            ],
            "settings.customAI.preset.concise": [.en: "Concise", .es: "Conciso", .pt: "Conciso"],
            "settings.customAI.preset.detailed": [.en: "Detailed", .es: "Detallado", .pt: "Detalhado"],
            "settings.customAI.preset.creative": [.en: "Creative", .es: "Creativo", .pt: "Criativo"],
            "settings.systemPrompt.placeholder": [
                .en: "Define the AI's persona or task...",
                .es: "Define la personalidad o tarea de la IA...",
                .pt: "Defina a personalidade ou tarefa da IA...",
            ],
            "settings.launchAtLogin": [.en: "Launch iBrain at login", .es: "Abrir iBrain al iniciar sesión", .pt: "Abrir iBrain no login"],
            "settings.cloud": [.en: "BRING YOUR OWN API KEY", .es: "TRAE TU PROPIA CLAVE API", .pt: "TRAGA SUA PRÓPRIA CHAVE API"],
            "settings.cloud.toggle": [
                .en: "Use my own API key instead of local",
                .es: "Usar mi propia clave API en vez de local",
                .pt: "Use minha própria chave API em vez de local",
            ],
            "settings.cloud.test": [.en: "Test key", .es: "Probar clave", .pt: "Testar chave"],
            "settings.cloud.save": [.en: "Save key changes", .es: "Guardar cambios de clave", .pt: "Salvar alterações da chave"],
            "settings.cloud.saveFailed": [.en: "Keychain could not save this key.", .es: "Keychain no pudo guardar esta clave.", .pt: "O Keychain não conseguiu salvar esta chave."],
            "settings.cloud.valid": [.en: "Working", .es: "Funciona", .pt: "Funcionando"],
            "settings.cloud.invalid": [.en: "Could not validate", .es: "No se pudo validar", .pt: "Não foi possível validar"],
            "settings.cloud.note": [
                .en: "Save a key to macOS Keychain before using cloud mode; clear and save to remove it. Cloud prompts go to your chosen provider and may be billed. The test sends a small request. Local mode uses Ollama instead.",
                .es: "Guarda una clave en Keychain antes de usar la nube; borrala y guarda para eliminarla. Los mensajes se envían al proveedor elegido y pueden tener costo. La prueba envía una solicitud pequeña. El modo local usa Ollama.",
                .pt: "Salve uma chave no Keychain antes de usar a nuvem; limpe e salve para removê-la. As mensagens vão ao provedor escolhido e podem gerar cobrança. O teste envia uma pequena solicitação. O modo local usa Ollama.",
            ],
            "chat.cloud": [.en: "Cloud", .es: "Nube", .pt: "Nuvem"],
            "cloud.missing.title": [.en: "Cloud key needed", .es: "Falta una clave de nube", .pt: "Chave de nuvem necessária"],
            "cloud.missing.body": [.en: "Cloud mode is selected, but no key is saved for this provider. Add one in Settings, or turn off cloud mode to use local Ollama.", .es: "Elegiste el modo nube, pero no hay una clave guardada para este proveedor. Agregá una en Ajustes o desactivá la nube para usar Ollama local.", .pt: "O modo de nuvem está selecionado, mas nenhuma chave foi salva para este provedor. Adicione uma em Configurações ou desative a nuvem para usar o Ollama local."],
            "settings.danger": [.en: "DANGER ZONE", .es: "ZONA DE PELIGRO", .pt: "ZONA DE PERIGO"],
            "settings.deleteAll": [.en: "Delete all chats", .es: "Eliminar todos los chats", .pt: "Deletar todos os chats"],
            "settings.deleteAll.confirmTitle": [
                .en: "Delete all chats?",
                .es: "¿Eliminar todos los chats?",
                .pt: "Deletar todos os chats?",
            ],
            "settings.deleteAll.confirmBody": [
                .en: "This permanently removes every conversation. This can't be undone.",
                .es: "Esto elimina permanentemente todas las conversaciones. No se puede deshacer.",
                .pt: "Isso remove permanentemente cada conversa. Isso não pode ser desfeito.",
            ],
            "settings.deleteAll.confirm": [.en: "Delete", .es: "Eliminar", .pt: "Deletar"],
            "settings.cancel": [.en: "Cancel", .es: "Cancelar", .pt: "Cancelar"],
            "settings.version": [
                .en: "iBrain · iSuite Office",
                .es: "iBrain · iSuite Office",
                .pt: "iBrain · iSuite Office",
            ],

            "menu.open": [.en: "Open iBrain", .es: "Abrir iBrain", .pt: "Abrir iBrain"],
            "menu.quit": [.en: "Quit iBrain", .es: "Salir de iBrain", .pt: "Sair do iBrain"],

            "chat.deleteChat": [.en: "Delete chat", .es: "Eliminar chat", .pt: "Deletar chat"],

            "onboarding.title": [.en: "Welcome to iBrain", .es: "Bienvenido a iBrain", .pt: "Bem-vindo ao iBrain"],
            "onboarding.body": [
                .en: "A free AI chat using local Ollama by default. Cloud APIs are optional in Settings.",
                .es: "Un chat de IA gratuito que usa Ollama local por defecto. Las API de nube son opcionales en Ajustes.",
                .pt: "Um chat de IA gratuito que usa o Ollama local por padrão. APIs de nuvem são opcionais em Configurações.",
            ],
            "onboarding.point.private": [
                .en: "Local-mode prompts stay on this Mac",
                .es: "Los mensajes del modo local quedan en esta Mac",
                .pt: "Mensagens do modo local ficam neste Mac",
            ],
            "onboarding.point.offline": [
                .en: "Local chat works offline after Ollama and a model are installed",
                .es: "El chat local funciona sin conexión tras instalar Ollama y un modelo",
                .pt: "O chat local funciona offline após instalar Ollama e um modelo",
            ],
            "onboarding.point.custom": [
                .en: "Customize how it responds in Settings → Custom AI",
                .es: "Personaliza cómo responde en Ajustes → IA Personalizada",
                .pt: "Personalize como responde em Configurações → IA Personalizada",
            ],
            "onboarding.dismiss": [.en: "Get started", .es: "Comenzar", .pt: "Começar"],
            "onboarding.selectLanguage": [.en: "Select your language", .es: "Selecciona tu idioma", .pt: "Selecione seu idioma"],
        ]

        return table[key]?[lang] ?? key
    }
}
