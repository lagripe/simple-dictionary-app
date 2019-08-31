import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:responsive_container/responsive_container.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanelPage> {
  final DatabaseName = "data";
  final PendingDatabaseName = "pendingData";
  Widget _buildListViewTile(DocumentSnapshot doc) {
    print(doc.documentID);
    return Card(
      color: Colors.grey[300],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResponsiveContainer(
            margin: EdgeInsets.only(left: 5, top: 5),
            heightPercent: 100,
            widthPercent: 85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(
                      doc['term'],
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        doc['submittedBy'],
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    'Definition',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  'Lorem ipsum dolor sit amet, vis te dicta aliquid mnesarchum, eum splendide intellegebat an.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Example',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Lorem ipsum dolor sit amet, vis te dicta aliquid mnesarchum, eum splendide intellegebat an.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                onTap: () {

                  Firestore.instance
                      .collection(DatabaseName)
                      .document()
                      .setData(doc.data);
                  Firestore.instance
                      .collection(PendingDatabaseName)
                      .document(doc.documentID)
                      .delete();
                  showDialog(
                      context: context,
                      builder: (context) {
                        return Platform.isAndroid
                            ? AlertDialog(
                                title: Text('Submition Successful'),
                                content: Text('The term has been added'),
                              )
                            : CupertinoAlertDialog(
                                title: Text('Submition Successful'),
                                content: Text('The term has been added'),
                              );
                      });
                },
                child: Icon(
                  Icons.add,
                  size: 30,
                  color: Colors.green,
                ),
              ),
              InkWell(
                onTap: () {
                  Firestore.instance
                      .collection(PendingDatabaseName)
                      .document(doc.documentID)
                      .delete();
                  showDialog(
                      context: context,
                      builder: (context) {
                        return Platform.isAndroid
                            ? AlertDialog(
                                title: Text('Term removed'),
                                content: Text('The term has been removed'),
                              )
                            : CupertinoAlertDialog(
                                title: Text('Term removed'),
                                content: Text('The term has been removed'),
                              );
                      });
                },
                child: Icon(
                  Icons.remove,
                  size: 30,
                  color: Colors.red[700],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Admin Panel'),
      ),
      body: ResponsiveContainer(
        heightPercent: 100,
        widthPercent: 100,
        child: StreamBuilder(
          stream:
              Firestore.instance.collection(PendingDatabaseName).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            else {
              return ListView.builder(
                  itemExtent: 150,
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) =>
                      _buildListViewTile(snapshot.data.documents[index]));
            }
          },
        ),
      ),
    );
  }
}
