import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notas_diarias/helper/AnotacaoHelper.dart';
import 'model/Anotacao.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final _db = AnotacaoHelper();
  List<Anotacao> _anotacoes = [];

  _exibirTelaCadastro({Anotacao? anotacao}) {
    String textoSalvarAtualizar = "";
    if (anotacao == null) {
      //salvando
      _tituloController.text = "";
      _descricaoController.text = "";
      textoSalvarAtualizar = "Salvar";
    } else {
      //atualizar
      _tituloController.text = anotacao.titulo!;
      _descricaoController.text = anotacao.descricao!;
      textoSalvarAtualizar = "Atualizar";
    }

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("$textoSalvarAtualizar anotação"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _tituloController,
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: "Título", hintText: "Insira o título"),
                ),
                TextField(
                  controller: _descricaoController,
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: "Descrição",
                      hintText: "Insira a descrição :)"),
                )
              ],
            ),
            actions: [
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      primary: Colors.purple, onPrimary: Colors.white),
                  child: Text("Cancelar")),
              ElevatedButton(
                  onPressed: () {
                    //salvar
                    _salvarAtualizarAnotacao(anotacaoSelecionada: anotacao);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      primary: Colors.purple, onPrimary: Colors.white),
                  child: Text(textoSalvarAtualizar))
            ],
          );
        });
  }

  _recuperarAnotacoes() async {
    List anotacoesRecuperadas = await _db.recuperarAnotacoes();

    List<Anotacao> listaTemporaria = [];
    for (var item in anotacoesRecuperadas) {
      Anotacao anotacao = Anotacao.fromMap(item);
      listaTemporaria.add(anotacao);
    }

    setState(() {
      _anotacoes = listaTemporaria;
    });
    listaTemporaria = [];
  }

  _salvarAtualizarAnotacao({Anotacao? anotacaoSelecionada}) async {
    String titulo = _tituloController.text;
    String descricao = _descricaoController.text;

    if (anotacaoSelecionada == null) {
      //salvar
      Anotacao anotacao =
          Anotacao(titulo, descricao, DateTime.now().toString());
      int resultado = await _db.salvarAnotacao(anotacao);
    } else {
      //atualizar
      anotacaoSelecionada.titulo = titulo;
      anotacaoSelecionada.descricao = descricao;
      anotacaoSelecionada.data = DateTime.now().toString();
      int resultado = await _db.atualizarAnotacao(anotacaoSelecionada);
    }

    //  if (kDebugMode) {
    //    print("salvar anotacao: " + resultado.toString() );
    //  }

    _tituloController.clear();
    _descricaoController.clear();

    _recuperarAnotacoes();
  }

  _formatarData(String data) {
    initializeDateFormatting("pt_BR");

    var formatador = DateFormat.yMd("pt_BR");

    DateTime dataConvertida = DateTime.parse(data);
    String dataFormatada = formatador.format(dataConvertida);

    return dataFormatada;
  }

  _salvarAnotacaoSnack(Anotacao ultimaAnotacaoRemovida) async {
    Anotacao anotacao = Anotacao(ultimaAnotacaoRemovida.titulo,
        ultimaAnotacaoRemovida.descricao, DateTime.now().toString());
    int i = await _db.salvarAnotacaoSnackBar(anotacao);
    _recuperarAnotacoes();
  }

  _removerAnotacao(int id) async {
    await _db.removerAnotacao(id);

    _recuperarAnotacoes();
  }

  @override
  void initState() {
    super.initState();
    _recuperarAnotacoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Minhas anotações"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[Colors.orange, Colors.pinkAccent])),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: ListView.builder(
                  itemCount: _anotacoes.length,
                  itemBuilder: (context, index) {
                    final anotacao = _anotacoes[index];

                    return Dismissible(
                        key: Key(
                            DateTime.now().millisecondsSinceEpoch.toString()),
                        background: Container(
                          color: Colors.red,
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                Icons.delete,
                                color: Colors.white,
                              )
                            ],
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          Anotacao _ultimaAnotacaoRemovida = anotacao;
                          //deleta anotação
                          _removerAnotacao(anotacao.id!);

                          //snackbar
                          final snackbar = SnackBar(
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 5),
                            content: Text("Anotação removida!"),
                            action: SnackBarAction(
                                label: "Desfazer",
                                textColor: Colors.white,
                                onPressed: () {
                                  _salvarAnotacaoSnack(_ultimaAnotacaoRemovida);
                                }),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(snackbar);
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(anotacao.titulo!),
                            subtitle: Text(""
                                "${_formatarData(anotacao.data!)} - "
                                "${anotacao.descricao}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    _exibirTelaCadastro(anotacao: anotacao);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        top: 16, bottom: 16, left: 5, right: 5),
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _removerAnotacao(anotacao.id!);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        top: 16, bottom: 16, left: 5, right: 5),
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ));
                  }))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _exibirTelaCadastro();
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        child: Icon(Icons.note_add),
      ),
    );
  }
}
