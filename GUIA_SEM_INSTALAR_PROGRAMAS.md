# ObraControl: gerar APK sem instalar programas

O aplicativo e DEMONSTRATIVO: credenciais de teste, dados somente no aparelho, sem contas reais e sem sincronizacao. Nao use dados sensiveis.

1. Crie uma conta gratuita em https://github.com e entre.
2. Clique em **New repository**, use o nome `obracontrol`, mantenha o repositorio **Private** e clique em **Create repository**.
3. Descompacte o ZIP no computador. Dentro da pasta `obracontrol`, selecione `lib`, `.github`, `pubspec.yaml` e `README.md` (pode incluir este guia). Arraste para a area **uploading an existing file** do repositorio recem-criado. OBS: a pasta `.github` pode estar oculta no Windows; habilite `Itens ocultos` no Explorador.
4. Clique em **Commit changes**. Aguarde o processamento em **Actions** > **Gerar APK de teste**. Se necessario, clique em **Run workflow**.
5. Abra a execucao com indicador verde e, na secao **Artifacts**, clique em **ObraControl-Android-APK** para baixar o APK (ou um ZIP que o contem, dependendo da plataforma).
6. Passe o APK para o celular Android, abra pelo gerenciador de arquivos e autorize instalacao de apps deste arquivo/fonte SOMENTE se reconhecer o arquivo que voce mesmo gerou. O Android pode alertar que e um aplicativo desconhecido, pois e um APK de teste.

Contas demonstrativas: `admin@obracontrol.demo` ou `equipe@obracontrol.demo`; senha `123456`.

Se surgir erro na tela Actions, copie o texto da mensagem de erro para o chat para corrigirmos.

Nao e necessario instalar Flutter ou Android Studio no computador. O GitHub Actions executa a compilacao em um servidor remoto. O processo nao foi executado nesta entrega; o ZIP contem apenas a configuracao para executar la.
