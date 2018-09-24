import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo List',
      color:  Colors.green,
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyPage(),
    );
  }
}

class MyPage extends StatefulWidget {
  @override
  MyPageState createState() => new MyPageState();
}

class MyPageState extends State<MyPage> {
  var items = new List<String>();
  var indx = 0;
  var edt = false;
  var txtDList = new List<TextDecoration>();
  var txtDDone = new List<String>();
  var itemIds = new List<int>();
   final myController = TextEditingController();
  Database db;
  String dbPath;

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
     create_and_Open_DB_and_GetData();
  }

  Future create_and_Open_DB_and_GetData() async {
    Directory path = await getApplicationDocumentsDirectory();
    dbPath = p.join(path.path, "db2.db");
    print("db path = $dbPath");
    db = await openDatabase(dbPath, version: 1, onCreate: this.createTable);
    getData();
  }

  Future createTable(Database db, int version) async {
   await db.execute("""CREATE TABLE IF NOT EXISTS todoItem (id INTEGER PRIMARY KEY,item TEXT NOT NULL,done TEXT NOT NULL)""");
    await db.close();
  }

  Future getData() async {
      db = await openDatabase(dbPath);
      var count = Sqflite.firstIntValue(await db.rawQuery('select count(*) from todoItem'));
     if (count != 0) {
      try {
     List<Map> list = await db.rawQuery('SELECT * FROM todoItem');
     await db.close();
    items.clear();
   txtDDone.clear();
   txtDList.clear();
   itemIds.clear();
   for(int i = 0; i < list.length; i++) {
     items.add(list[i]["item"]);
     txtDDone.add(list[i]["done"]);
     itemIds.add(list[i]["id"]);
   }
   for(int i = 0; i < txtDDone.length; i++) {
        if(txtDDone[i] == 'true'){ txtDList.insert(i, TextDecoration.lineThrough);}
        else { txtDList.insert(i, TextDecoration.none);}
     }
     setState(() {});
  }  catch(e) {}
 }
}

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: Text('ToDo List'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: <Widget>[
          new IconButton(icon: const Icon(Icons.add), onPressed: () {
            edt = false;
            _showDialog();
          }),
        ],
      ),
      body:
      makeListView(),
    );
  }

  _showDialog() async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            contentPadding: const EdgeInsets.all(16.0),
            content: new Row(
              children: <Widget>[
                new Expanded(
                  child: new TextField(
                    controller: myController,
                    autofocus: true,
                    decoration: new InputDecoration(
                      labelText: 'Add item:',
                    ),
                  ),
                )
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                onPressed: () async {
                  await changeListView();
                  myController.text = "";
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
              new FlatButton(
                onPressed: () {
                  if (edt) {
                    edt = false;
                  }
                  myController.text = "";
                  Navigator.pop(context);},
                child: const Text('cancel'),
              ),
            ],
          );
        }
    );
  }

  changeListView()  async {
    if (edt) {
      items[indx] = myController.text;
      try {
        db = await openDatabase(dbPath);
        await db.rawQuery('update todoItem set item = ? where id = ?',[myController.text,itemIds[indx]]);
        await db.close();

      } catch(e) {
        print("error in update: $e");
      }
    }
    else {
      if (items == null) {
        items = new List<String>();
        txtDDone = new List<String>();
      }
      try{
        items.add(myController.text);
        txtDDone.add("false");
        txtDList.add(TextDecoration.none);
      } catch(e) {
        print("error in adding: $e");
      }
      try {
          db = await openDatabase(dbPath);
          await db.rawQuery('insert into todoItem(item,done) values("${myController.text}","false")');
          await db.close();

      } catch(e) {
        print("error in insert: $e");
      }
      }
      setState(() {});
  }

  Widget makeListView() {
    return new LayoutBuilder(builder: (context, constraint) {
      return new ListView.builder(
        itemCount: items.length == null ? 0 : items.length,
        itemBuilder: (context, index) {
          return new LongPressDraggable(
            key: new ObjectKey(index),
            data: index,
            child: new DragTarget<int>(
              onAccept: (int data) async {
                await _handleAccept(data, index);
              },
              builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                return new Card(
                    child: new Column(
                      children: <Widget>[
                        new ListTile(
                          leading: new IconButton(icon: const Icon(Icons.strikethrough_s), color: Colors.blue, onPressed: () async {
                            indx = index;
                            await makeStrikeThoroughText();
                          }),
                          trailing: new IconButton(icon: const Icon(Icons.delete), color: Colors.red, onPressed: () async {
                            indx = index;
                            await deleteValue();
                          }),
                          title:
                         Text('${items[index]}', style: TextStyle(decoration: txtDList[index]),),
                          onTap: () {
                            edt = true;
                            indx = index;
                            myController.text = items[index];
                            _showDialog();
                          },
                        ),
                      ],
                    )
                );
              },
              onLeave: (int data) {},
              onWillAccept: (int data) {
                return true;
              },
            ),
            onDragStarted: () {
              Scaffold.of(context).showSnackBar(new SnackBar (
                content: new Text("Drag the row onto another row to change places"),
              ));
              },
            onDragCompleted: () {},
            feedback: new SizedBox(
                width: constraint.maxWidth,
                child: new Card (
                  child: new Column(
                    children: <Widget>[
                      new ListTile(
                        leading: new IconButton(icon: const Icon(Icons.strikethrough_s), color: Colors.blue, onPressed: () async {
                          indx = index;
                        }),
                        trailing: new IconButton(icon: const Icon(Icons.delete), color: Colors.red, onPressed: () async {
                          indx = index;
                        }),
                        title:
                        Text('${items[index]}', style: TextStyle(decoration: txtDList[index]),),
                        onTap: () {
                          edt = true;
                          indx = index;
                          myController.text = items[index];
                        },
                      ),
                    ],
                  ),
                  elevation: 18.0,
                )
            ),
            childWhenDragging: new Container(),
          );
        },
      );
    });
  }

  _handleAccept(int data, int index) async {
    String itemToMove = items[data];
    items.removeAt(data);
    items.insert(index, itemToMove);

    itemToMove = txtDDone[data];
    txtDDone.removeAt(data);
    txtDDone.insert(index, itemToMove);

    txtDList.clear();

    for(int i = 0; i < txtDDone.length; i++) {
      if (txtDDone[i] == "true") {
        txtDList.insert(i, TextDecoration.lineThrough);
      }
      else {
        txtDList.insert(i, TextDecoration.none);
      }
    }

    try {
      db = await openDatabase(dbPath);
      await db.rawQuery('delete from todoItem');
      await db.close();

    } catch(e) {
      print("error in deleting: $e");
    }

   for (int i=0; i < items.length; i++) {
      try {
        db = await openDatabase(dbPath);
        await db.rawQuery('insert into todoItem(item,done) values("${items[i]}","${txtDDone[i]}")');
         await db.close();
      } catch (e) {
        print("error in update: $e");
      }
    }

    setState(() {});
  }

  deleteValue() async {
    items.removeAt(indx);
    txtDDone.removeAt(indx);
    txtDList.removeAt(indx);

    try {
      db = await openDatabase(dbPath);
      await db.rawQuery('delete from todoItem where id = ?',[itemIds[indx]]);
      await db.close();

    } catch(e) {
      print("error in delete: $e");
    }
    setState(() {});
  }

  makeStrikeThoroughText() async {
    if (txtDDone[indx] == "true") {
      txtDDone[indx] = "false";
      txtDList[indx] = TextDecoration.none;
    }
    else {
      txtDDone[indx] = "true";
      txtDList[indx] = TextDecoration.lineThrough;
    }
   try {
      db = await openDatabase(dbPath);
      await db.rawQuery('update todoItem set done = ? where id = ?',["${txtDDone[indx]}",itemIds[indx]]);
      await db.close();
    } catch(e) {
      print("error in update: $e");
    }
     setState(() {});
    }
}

