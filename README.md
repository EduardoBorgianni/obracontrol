# ObraControl — v0.1 Android / Flutter

## O que já funciona
- Tela de acesso com **dois usuários demonstrativos** e perfis Administrador / Equipe.
- Cadastrar, editar, listar e excluir obras (exclusão restrita ao administrador).
- Selecionar uma obra no painel e registrar ordens de serviço, finanças, tarefas, materiais e diário, associados à obra.
- Resumo das receitas, despesas e saldo por obra.
- Persistência **local no aparelho** usando SharedPreferences.
- Cadastro/edição e identificação do usuário responsável por cada lançamento no registro.

## Importante: limites de segurança e operação
Este é um protótipo de demonstração, **não um sistema multiusuário em produção**. Os logins são locais, fixos e inseguros, com senha de teste pública (123456); não há servidor, sincronização entre aparelhos, criptografia de banco, regras de acesso verificadas em backend, backup, anexos fotográficos nem PDF. Não colocar informações reais ou sensíveis. Para uso por equipes, implementar Firebase Authentication (ou Supabase Auth), banco Firestore (ou PostgreSQL) com controle de acesso no servidor, isolamento por empresa, trilha de auditoria e política de backup.

## Rodar no Android
1. Instale Flutter SDK, Android Studio e Android SDK. Confirme: `flutter doctor`.
2. Em terminal dentro desta pasta, execute `flutter create --platforms android .` para gerar arquivos nativos (não incluídos para facilitar compatibilidade com a versão Flutter instalada).
3. Execute `flutter pub get`.
4. Com emulador Android ligado ou celular com depuração USB: `flutter run`.
5. Para gerar APK de testes: `flutter build apk --debug` (gera `build/app/outputs/flutter-apk/app-debug.apk`).

**Usuários demonstrativos:**
- admin@obracontrol.demo / 123456
- equipe@obracontrol.demo / 123456

## Evolução recomendada da arquitetura
```
Flutter Android
  ├── UI: Dashboard e 6 módulos
  ├── Domain: Obra, OS, LancamentoFinanceiro, Tarefa, Material, Diario
  ├── Data: repository (substituir armazenamento local de demo)
  └── Serviços cloud
       ├── Firebase Authentication: contas individuais e convite
       ├── Firestore: obras/{id}/...; empresas/{id}/membros
       ├── Firebase Storage: fotos e documentos
       ├── Cloud Functions: contabilidade de estoque, números de OS, relatórios
       └── Security Rules: acesso limitado por empresa e papel
```

## Regras funcionais importantes para próximas versões
- `obraId` obrigatório em todo registro exceto cadastro de obra.
- Cada movimentação de estoque deve ser transacional, com origem, destino, data, usuário e custo.
- Não lançar custo duplicado quando uma saída do estoque já tiver sido apropriada em compras.
- Permissões precisam ser impostas **no backend**, não apenas pela interface.
- Implementar diário com fotos, clima, observações e assinatura; exportação e numeração de documentos.
- Armazenar valores financeiros em centavos inteiros ou decimal de precisão fixa, nunca double como fonte de verdade.
- Não apagar registros históricos financeiros por exclusão em cascata; preferir arquivamento e trilha de auditoria.
