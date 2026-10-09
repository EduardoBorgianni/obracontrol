import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const ObraControl()); }

const navy = Color(0xFF13243B);
const gold = Color(0xFFF2B83F);

class ObraControl extends StatelessWidget {
  const ObraControl({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'ObraControl', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: navy), useMaterial3: true,
      appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
      scaffoldBackgroundColor: const Color(0xFFF3F5F8)), home: const AppRoot());
}

class Store extends ChangeNotifier {
  final Map<String,List<Map<String,dynamic>>> data = {for (final k in sections.keys) k: []};
  String? email;
  String? role;
  String? selectedWork;
  late SharedPreferences prefs;
  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    for (final k in sections.keys) {
      try { final decoded = jsonDecode(prefs.getString('data_$k') ?? '[]') as List;
        data[k] = decoded.map((e) => Map<String,dynamic>.from(e as Map)).toList();
      } catch (_) { data[k] = []; }
    }
    email = prefs.getString('session_email');
    role = email == null ? null : (email == 'admin@obracontrol.demo' ? 'Administrador' : 'Equipe');
    selectedWork = prefs.getString('selected_work');
    if (selectedWork != null && !data['Obras']!.any((w) => w['id'] == selectedWork)) selectedWork = null;
    notifyListeners();
  }
  Future<bool> login(String user, String pass) async {
    final u = user.trim().toLowerCase();
    if (!((u == 'admin@obracontrol.demo' && pass == '123456') ||
          (u == 'equipe@obracontrol.demo' && pass == '123456'))) return false;
    email = u; role = u.startsWith('admin') ? 'Administrador' : 'Equipe';
    await prefs.setString('session_email', u); notifyListeners(); return true;
  }
  Future<void> logout() async { email = null; role = null; await prefs.remove('session_email'); notifyListeners(); }
  Future<void> pickWork(String? id) async { selectedWork = id; if (id == null) { await prefs.remove('selected_work'); } else {await prefs.setString('selected_work',id);} notifyListeners(); }
  List<Map<String,dynamic>> items(String section) => section == 'Obras' ? [...data[section]!] :
      data[section]!.where((x) => x['obraId'] == selectedWork).toList();
  Future<void> save(String section, Map<String,dynamic> item) async {
    final list = data[section]!;
    final index = list.indexWhere((x) => x['id'] == item['id']);
    if (index >= 0) { list[index] = item; } else { list.add(item); }
    await prefs.setString('data_$section', jsonEncode(list)); notifyListeners();
  }
  Future<void> remove(String section, String id) async {
    data[section]!.removeWhere((x) => x['id'] == id);
    if (section == 'Obras') {
      for (final other in sections.keys.where((x) => x != 'Obras')) {
        data[other]!.removeWhere((e) => e['obraId'] == id);
        await prefs.setString('data_$other', jsonEncode(data[other]));
      }
      if (selectedWork == id) await pickWork(null);
    }
    await prefs.setString('data_$section', jsonEncode(data[section])); notifyListeners();
  }
}

// Tipos usados por todos os módulos: o identificador de obra relaciona os registros.
const Map<String,List<String>> sections = {
  'Obras': ['Nome da obra','Cliente','Endereço','Responsável','Data de início','Previsão de término','Orçamento (R\$)','Status'],
  'Ordens de Serviço': ['Número da OS','Descrição','Responsável','Prazo','Status','Observações'],
  'Financeiro': ['Descrição','Tipo (Receita/Despesa)','Categoria','Valor (R\$)','Data','Fornecedor / Cliente'],
  'Tarefas': ['Tarefa','Responsável','Prazo','Prioridade','Status','Observações'],
  'Materiais': ['Material','Unidade','Quantidade recebida','Quantidade consumida','Custo unitário (R\$)','Fornecedor'],
  'Diário de Obra': ['Data','Clima','Efetivo de pessoal','Serviços executados','Equipamentos','Ocorrências'],
};
const Map<String,IconData> sectionIcons = {
  'Obras': Icons.apartment, 'Ordens de Serviço': Icons.assignment,
  'Financeiro': Icons.account_balance_wallet, 'Tarefas': Icons.task_alt,
  'Materiais': Icons.inventory_2, 'Diário de Obra': Icons.menu_book,
};
double money(dynamic v) => double.tryParse(v.toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0;
String real(double n) => 'R\$ ${n.toStringAsFixed(2).replaceAll('.', ',')}';

class AppRoot extends StatefulWidget { const AppRoot({super.key}); @override State<AppRoot> createState() => _AppRootState(); }
class _AppRootState extends State<AppRoot> {
  final store = Store(); bool ready = false;
  @override void initState() {super.initState(); store.init().then((_) {if(mounted) setState(()=>ready=true);}); store.addListener(refresh);}
  void refresh() {if (mounted) setState((){});}
  @override void dispose() {store.removeListener(refresh); store.dispose(); super.dispose();}
  @override Widget build(BuildContext context) => !ready ? const Scaffold(body: Center(child:CircularProgressIndicator())) :
    store.email == null ? LoginPage(store:store) : HomePage(store:store);
}

class LoginPage extends StatefulWidget {final Store store; const LoginPage({super.key,required this.store}); @override State<LoginPage> createState()=>_LoginPageState();}
class _LoginPageState extends State<LoginPage> {
  final user=TextEditingController(text:'admin@obracontrol.demo');
  final pass=TextEditingController(text:'123456'); String? error;
  @override void dispose(){user.dispose();pass.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(body:Center(child:SingleChildScrollView(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Padding(padding:const EdgeInsets.all(24),child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Icon(Icons.construction,size:56,color:navy), const SizedBox(height:14),const Text('ObraControl',textAlign:TextAlign.center,style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
    const SizedBox(height:8),const Text('Acesso individual • versão demonstrativa',textAlign:TextAlign.center),const SizedBox(height:24),
    TextField(controller:user,decoration:const InputDecoration(labelText:'E-mail',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'Senha',border:OutlineInputBorder())),
    if(error!=null) Padding(padding:const EdgeInsets.only(top:10),child:Text(error!,style:const TextStyle(color:Colors.red))),
    const SizedBox(height:16),FilledButton(onPressed:() async {if(!await widget.store.login(user.text,pass.text) && mounted) setState(()=>error='Credenciais de demonstração inválidas');},child:const Text('Entrar')),
    const SizedBox(height:16),const Text('Contas de teste (senha 123456):\nadmin@obracontrol.demo\nequipe@obracontrol.demo',style:TextStyle(fontSize:12)),
    const SizedBox(height:8),const Text('ATENÇÃO: login e dados apenas neste aparelho. Não utilize dados reais ou sensíveis. Ainda não existe sincronização nem autenticação segura.',style:TextStyle(fontSize:12,color:Colors.deepOrange)),
  ]))))))));
}

class HomePage extends StatelessWidget {final Store store; const HomePage({super.key,required this.store});
 @override Widget build(BuildContext context){final works=store.data['Obras']!;final selected=works.where((e)=>e['id']==store.selectedWork).toList();
 return Scaffold(appBar:AppBar(title:const Text('ObraControl'),actions:[IconButton(tooltip:'Sair',onPressed:store.logout,icon:const Icon(Icons.logout))]),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(color:navy,child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Olá, ${store.role}',style:const TextStyle(color:gold,fontWeight:FontWeight.bold)),
      Text(store.email!,style:const TextStyle(color:Colors.white70,fontSize:12)),const SizedBox(height:14),
      const Text('Obra em foco',style:TextStyle(color:Colors.white)),
      DropdownButtonFormField<String>(value:selected.isEmpty?null:store.selectedWork,dropdownColor:navy,style:const TextStyle(color:Colors.white),
        decoration:const InputDecoration(enabledBorder:UnderlineInputBorder(borderSide:BorderSide(color:Colors.white60))),hint:const Text('Selecione uma obra',style:TextStyle(color:Colors.white70)),
        items:works.map((w)=>DropdownMenuItem(value:w['id'].toString(),child:Text(w['Nome da obra'].toString(),overflow:TextOverflow.ellipsis))).toList(),
        onChanged:store.pickWork),
      if(works.isEmpty) const Padding(padding:EdgeInsets.only(top:8),child:Text('Cadastre a primeira obra para começar.',style:TextStyle(color:Colors.white70))),
    ]))),const SizedBox(height:14),
    Row(children:[Expanded(child:_stat('Obras',works.length.toString())),const SizedBox(width:10),Expanded(child:_stat('Tarefas abertas',store.items('Tarefas').where((t)=>t['Status']!='Concluída').length.toString()))]),
    const SizedBox(height:16),GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.45,crossAxisSpacing:10,mainAxisSpacing:10,
      children:sections.keys.map((s)=>Card(child:InkWell(borderRadius:BorderRadius.circular(12),onTap:(){if(s!='Obras'&&store.selectedWork==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Selecione uma obra primeiro.')));return;}Navigator.push(context,MaterialPageRoute(builder:(_)=>SectionPage(store:store,section:s)));},child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(sectionIcons[s],size:32,color:navy),const SizedBox(height:9),Text(s,textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w600))])))).toList()),
    if(store.selectedWork!=null) ...[const SizedBox(height:14), _financialSummary(store)],
    const SizedBox(height:20),const Text('PROTÓTIPO LOCAL • NÃO USAR EM PRODUÇÃO',textAlign:TextAlign.center,style:TextStyle(color:Colors.deepOrange,fontSize:11,fontWeight:FontWeight.w600)),
 ]));}
 Widget _stat(String label,String value)=>Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(children:[Text(value,style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)),Text(label,textAlign:TextAlign.center,style:const TextStyle(fontSize:12))])));
 Widget _financialSummary(Store s){double income=0,expense=0;for(final e in s.items('Financeiro')){if(e['Tipo (Receita/Despesa)']=='Receita'){income+=money(e['Valor (R\$)']);}else{expense+=money(e['Valor (R\$)']);}}
 return Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Resumo financeiro da obra',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),Text('Receitas: ${real(income)}'),Text('Despesas: ${real(expense)}'),Text('Saldo: ${real(income-expense)}',style:const TextStyle(fontWeight:FontWeight.bold))])));}
}

class SectionPage extends StatelessWidget {final Store store;final String section;const SectionPage({super.key,required this.store,required this.section});
 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_){final items=store.items(section);
 return Scaffold(appBar:AppBar(title:Text(section)),floatingActionButton:FloatingActionButton.extended(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>EditPage(store:store,section:section))),icon:const Icon(Icons.add),label:const Text('Novo')),
 body:items.isEmpty?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(sectionIcons[section],size:56,color:Colors.grey),const SizedBox(height:10),const Text('Nenhum registro ainda'),const SizedBox(height:8),const Text('Toque em Novo para cadastrar.')])):
 ListView.builder(padding:const EdgeInsets.fromLTRB(12,12,12,90),itemCount:items.length,itemBuilder:(context,i){final item=items[i];final primary=item[sections[section]!.first]?.toString()??'Registro';
 return Card(child:ListTile(leading:Icon(sectionIcons[section],color:navy),title:Text(primary.isEmpty?'Sem título':primary),subtitle:Text(sections[section]!.skip(1).take(3).map((field)=>item[field] == null||item[field].toString().isEmpty?'':'$field: ${item[field]}').where((x)=>x.isNotEmpty).join('\n'),maxLines:3),isThreeLine:true,
 onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>EditPage(store:store,section:section,existing:item))),
 trailing:store.role=='Administrador'?PopupMenuButton<String>(onSelected:(action)async{if(action=='delete'){final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Excluir registro?'),content:const Text('Esta ação não poderá ser desfeita.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),TextButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Excluir'))]));if(ok==true) await store.remove(section,item['id'].toString());}},itemBuilder:(_)=>[const PopupMenuItem(value:'delete',child:Text('Excluir'))]):null));}));});}
}

class EditPage extends StatefulWidget{final Store store; final String section;final Map<String,dynamic>? existing;const EditPage({super.key,required this.store,required this.section,this.existing});@override State<EditPage> createState()=>_EditPageState();}
class _EditPageState extends State<EditPage>{final formKey=GlobalKey<FormState>();final Map<String,TextEditingController> controllers={};
 @override void initState(){super.initState();for(final f in sections[widget.section]!) controllers[f]=TextEditingController(text:widget.existing?[f]?.toString()??'');}
 @override void dispose(){for(final c in controllers.values)c.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.existing==null?'Novo registro':'Editar registro')),body:Form(key:formKey,child:ListView(padding:const EdgeInsets.all(16),children:[
 ...sections[widget.section]!.map((f)=>Padding(padding:const EdgeInsets.only(bottom:14),child:_field(f))),
 FilledButton.icon(icon:const Icon(Icons.save),label:const Text('Salvar'),onPressed:() async{if(!formKey.currentState!.validate())return;
 final obj=<String,dynamic>{...?widget.existing,'id':widget.existing?['id']??DateTime.now().microsecondsSinceEpoch.toString(),
 'obraId':widget.section=='Obras'?null:widget.store.selectedWork,'createdBy':widget.existing?['createdBy']??widget.store.email,
 'updatedBy':widget.store.email,'updatedAt':DateTime.now().toIso8601String()};
 for(final e in controllers.entries) obj[e.key]=e.value.text.trim();
 await widget.store.save(widget.section,obj);
 if(widget.section=='Obras'&&widget.store.selectedWork==null) await widget.store.pickWork(obj['id'].toString());
 if(context.mounted)Navigator.pop(context);
 }),const SizedBox(height:20),const Text('Valores financeiros: informe números no formato 1250,50. A data é texto nesta versão inicial.',style:TextStyle(fontSize:12,color:Colors.black54))
 ])));
 Widget _field(String field){
 final options=<String,List<String>>{'Status':widget.section=='Obras'?['Planejada','Em andamento','Paralisada','Concluída']:['Aberta','Em andamento','Concluída','Cancelada'],
 'Prioridade':['Baixa','Média','Alta','Crítica'],'Tipo (Receita/Despesa)':['Receita','Despesa']};
 final items=options[field]; if(items!=null){return DropdownButtonFormField<String>(value:items.contains(controllers[field]!.text)?controllers[field]!.text:null,
 decoration:InputDecoration(labelText:field,border:const OutlineInputBorder()),items:items.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
 onChanged:(v)=>controllers[field]!.text=v??'',validator:(v)=>(v??'').isEmpty?'Campo obrigatório':null);}
 final numeric=field.contains('(R\$)')||field.startsWith('Quantidade')||field.startsWith('Custo unitário');
 return TextFormField(controller:controllers[field],keyboardType:numeric?const TextInputType.numberWithOptions(decimal:true):TextInputType.multiline,
 minLines:1,maxLines:field=='Serviços executados'||field=='Ocorrências'||field=='Descrição'?4:1,
 decoration:InputDecoration(labelText:field,border:const OutlineInputBorder()),
 validator:(v){if((v??'').trim().isEmpty && field==sections[widget.section]!.first)return 'Campo obrigatório';
 if(numeric&&(v??'').trim().isNotEmpty && double.tryParse(v!.replaceAll('.','').replaceAll(',','.'))==null)return 'Número inválido';return null;});
 }
}