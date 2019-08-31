import 'dart:math';
import 'package:astaray/CardObject.dart';
import 'package:astaray/StaticalObjects.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_container/responsive_container.dart';
import 'package:intl/intl.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:device_id/device_id.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  // Firebase Admob
  static String deviceId = "";
  static final MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
      keywords: <String>['games', 'books'],
      childDirected: false,
      designedForFamilies: false,
      testDevices: deviceId != null
          ? [deviceId]
          : null // Android emulators are considered test devices
      );
  BannerAd myBanner;
  BannerAd buildBanner() {
    return BannerAd(
        adUnitId: Platform.isAndroid
            ? "ca-app-pub-7573530280503593/6241895011"
            : "ca-app-pub-7573530280503593~8433245404",
        size: AdSize.smartBanner,
        targetingInfo: targetingInfo,
        listener: (MobileAdEvent event) {
          if (event == MobileAdEvent.loaded) myBanner..show();
          if (event == MobileAdEvent.failedToLoad) {
            myBanner = buildBanner()..load();
            print(event);
          }
          if (event == MobileAdEvent.closed) {
            setState(() {
              adClosed = true;
            });
            myBanner = buildBanner()..load();
          }
          if (event == MobileAdEvent.opened)
            setState(() {
              adClosed = false;
            });
        });
  }

  //-----------

  bool tes = false, rand = false, adClosed = false;
  TabController _tabController;
  String tabTitle = "Home";
  DateTime currentBackPressTime;
  int _count = 10;
  final DatabaseName = "data";
  final PendingDatabaseName = "pendingData";
  final scrollController = ScrollController();
  Stream<QuerySnapshot> searchRes;
  DocumentSnapshot randomRes;
  TextEditingController _textTerm,
      _textDef,
      _textExp,
      _textSub,
      _searchController;
  FocusNode focusDef, focusExp, focusSub;
  void getDeviceId() async {
    await DeviceId.getID.then((id) => deviceId = id);
  }

  Widget _buildListViewTile(DocumentSnapshot doc) {
    return Card(
      color: Colors.grey[300],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              margin: EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        doc['term'],
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                    doc['desc'],
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    'Example',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    doc['example'],
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: StaticalObject.bookmark.containsKey(doc.documentID)
                    ? Icon(
                        Icons.bookmark,
                        color: Colors.yellow[800],
                        size: 30,
                      )
                    : Icon(
                        Icons.bookmark_border,
                        size: 30,
                        color: Colors.grey[500],
                      ),
                onTap: () => setState(() {
                  if (StaticalObject.bookmark.containsKey(doc.documentID))
                    StaticalObject.bookmark.remove(doc.documentID);
                  else {
                    StaticalObject.bookmark[doc.documentID] = CardObject(
                        doc['term'],
                        doc['desc'],
                        doc['likes'],
                        doc.documentID,
                        doc['example'],
                        doc['submittedBy']);
                  }
                  StaticalObject.setBookmark();
                }),
              ),
              Container(
                child: Column(
                  children: <Widget>[
                    InkWell(
                      child: StaticalObject.likes.contains(doc.documentID)
                          ? Icon(
                              Ionicons.getIconData('ios-heart'),
                              size: 30,
                              color: Colors.red[800],
                            )
                          : Icon(
                              Ionicons.getIconData('ios-heart-empty'),
                              size: 30,
                              color: Colors.red[800],
                            ),
                      onTap: () {
                        setState(() {
                          if (StaticalObject.likes.contains(doc.documentID)) {
                            if (StaticalObject.bookmark
                                .containsKey(doc.documentID))
                              StaticalObject.bookmark[doc.documentID].likes--;
                            //
                            StaticalObject.likes.remove(doc.documentID);
                            //
                            doc.reference
                                .updateData({'likes': doc['likes'] - 1});
                          } else {
                            if (StaticalObject.bookmark
                                .containsKey(doc.documentID))
                              StaticalObject.bookmark[doc.documentID].likes++;
                            //
                            StaticalObject.likes.add(doc.documentID);
                            //
                            doc.reference
                                .updateData({'likes': doc['likes'] + 1});
                          }
                          StaticalObject.setLikes();
                          StaticalObject.setBookmark();
                        });
                      },
                    ),
                    Text(NumberFormat.compact().format(doc['likes']))
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void getRandom() async {
    QuerySnapshot querySnapshot =
        await Firestore.instance.collection(DatabaseName).getDocuments();
    if (querySnapshot.documents.length == 0) return;
    setState(() {
      rand = true;
    });
    setState(() {
      randomRes = querySnapshot
          .documents[Random().nextInt(querySnapshot.documents.length)];
    });
  }

  Widget _buildListViewBookmark(String id, CardObject object) {
    return Card(
      color: Colors.grey[300],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              margin: EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        object.term,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          object.submittedBy,
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
                    object.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    'Example',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    object.example,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: Icon(
                  Icons.delete,
                  size: 30,
                ),
                onTap: () => setState(() {
                  StaticalObject.bookmark.remove(id);
                  StaticalObject.setBookmark();
                }),
              ),
              Container(
                child: Column(
                  children: <Widget>[
                    InkWell(
                      child: StaticalObject.likes.contains(id)
                          ? Icon(
                              Ionicons.getIconData('ios-heart'),
                              size: 30,
                              color: Colors.red[800],
                            )
                          : Icon(
                              Ionicons.getIconData('ios-heart-empty'),
                              size: 30,
                              color: Colors.red[800],
                            ),
                      onTap: () {
                        setState(() {
                          if (StaticalObject.likes.contains(id)) {
                            StaticalObject.likes.remove(id);
                            Firestore.instance
                                .collection(DatabaseName)
                                .document(id)
                                .get()
                                .then((doc) {
                              doc.reference
                                  .updateData({'likes': doc['likes'] - 1});
                            });
                            object.likes--;
                          } else {
                            StaticalObject.likes.add(id);
                            Firestore.instance
                                .collection(DatabaseName)
                                .document(id)
                                .get()
                                .then((doc) {
                              doc.reference
                                  .updateData({'likes': doc['likes'] + 1});
                            });
                            object.likes++;
                          }
                          StaticalObject.setLikes();
                        });
                      },
                    ),
                    Text(NumberFormat.compact().format(object.likes))
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  List<Widget> _buildAlphabiticOrder() {
    List<Widget> out = new List<Widget>();
    for (int i = 'A'.codeUnitAt(0); i <= 'Z'.codeUnitAt(0); i++)
      out.add(
        Container(
          width: MediaQuery.of(context).size.width / 6,
          color: Colors.teal,
          child: InkWell(
            child: Center(
                child: Text(
              String.fromCharCode(i),
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )),
            onTap: () {
              setState(() {
                rand = false;
              });

              List<dynamic> d = List<dynamic>();
              d.add(String.fromCharCode(i));

              setState(() {
                searchRes = Firestore.instance
                    .collection(DatabaseName)
                    .where('searchKey', isEqualTo: String.fromCharCode(i))
                    .orderBy('likes', descending: true)
                    .snapshots();

                //print(docs.documents.length);
              });
            },
          ),
        ),
      );
    return out;
  }

  String getPageTitle(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "Search";
      case 2:
        return "Submition";
      case 3:
        return "Bookmark";
    }
  }

  Future<bool> BackPressedExit() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) < Duration(seconds: 2)) {
      currentBackPressTime = now;
      SystemNavigator.pop();
    }
    return Future.value(true);
  }

  @override
  void initState() {
    getDeviceId();
    FirebaseAdMob.instance
        .initialize(
      appId: Platform.isAndroid
          ? "ca-app-pub-7573530280503593~1383130636"
          : "ca-app-pub-7573530280503593~8433245404",
    )
        .then((response) {
      myBanner = buildBanner()
        ..load()
        ..show();
    });
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.offset) {
        setState(() {
          _count += _count;
        });
      }
    });
    focusDef = FocusNode();
    focusExp = FocusNode();
    focusSub = FocusNode();
    // TODO: implement initState
    super.initState();
    _textTerm = TextEditingController();
    _textDef = TextEditingController();
    _textExp = TextEditingController();
    _textSub = TextEditingController();
    _searchController = TextEditingController();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      tabTitle = getPageTitle(_tabController.index);
      _searchController.text = "";
      setState(() {
        searchRes = Firestore.instance
            .collection(DatabaseName)
            .where('searchKey', isEqualTo: 'A')
            .snapshots();
      });

      if (_tabController.index != 2) {
        _textTerm.text = "";
        _textDef.text = "";
        _textExp.text = "";
        _textSub.text = "";
      }
    });
  }

  @override
  void dispose() {
    myBanner?.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        height: adClosed ? 0.0 : 50,
        width: double.infinity,
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(tabTitle),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() {
            tabTitle = getPageTitle(index);

            _searchController.text = "";
            setState(() {
              searchRes = Firestore.instance
                  .collection(DatabaseName)
                  .where('searchKey', isEqualTo: 'A')
                  .snapshots();
            });

            if (index != 2) {
              _textTerm.text = "";
              _textDef.text = "";
              _textExp.text = "";
              _textSub.text = "";
            }
          }),
          labelStyle: TextStyle(fontSize: 12),
          tabs: <Widget>[
            Tab(
                icon: Platform.isAndroid
                    ? Icon(
                        Ionicons.getIconData('md-home'),
                        size: 30,
                      )
                    : Icon(
                        Ionicons.getIconData('ios-home'),
                        size: 30,
                      )),
            Tab(
                icon: Platform.isAndroid
                    ? Icon(
                        Ionicons.getIconData('md-search'),
                        size: 30,
                      )
                    : Icon(
                        Ionicons.getIconData('ios-search'),
                        size: 30,
                      )),
            Tab(
                icon: Platform.isAndroid
                    ? Icon(
                        Ionicons.getIconData('md-add'),
                        size: 30,
                      )
                    : Icon(
                        Ionicons.getIconData('ios-add'),
                        size: 30,
                      )),
            Tab(
                icon: Platform.isAndroid
                    ? Icon(
                        Ionicons.getIconData('md-bookmark'),
                        size: 30,
                      )
                    : Icon(
                        Ionicons.getIconData('ios-bookmark'),
                        size: 30,
                      )),
          ],
        ),
      ),
      body: WillPopScope(
        onWillPop: BackPressedExit,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
          child: Stack(
            children: <Widget>[
              TabBarView(
                controller: _tabController,
                children: <Widget>[
                  ResponsiveContainer(
                    heightPercent: 100,
                    widthPercent: 100,
                    child: StreamBuilder(
                      stream: Firestore.instance
                          .collection(DatabaseName)
                          .limit(_count)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());
                        else {
                          return ListView.builder(
                              controller: scrollController,
                              itemCount: snapshot.data.documents.length,
                              itemBuilder: (context, index) =>
                                  _buildListViewTile(
                                      snapshot.data.documents[index]));
                        }
                      },
                    ),
                  ),
                  SingleChildScrollView(
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.width / 6,
                            child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: _buildAlphabiticOrder()),
                          ),
                          ResponsiveContainer(
                            heightPercent: 10,
                            widthPercent: 100,
                            child: TextField(
                              textInputAction: TextInputAction.next,
                              controller: _searchController,
                              decoration: InputDecoration(
                                  icon: Icon(Icons.subject),
                                  labelText: 'Term',
                                  hintText: 'Type to search'),
                              onChanged: (text) {
                                if (text.isEmpty) return;
                                setState(() {
                                  rand = false;
                                });

                                List<dynamic> d = List<dynamic>();
                                d.add(text);

                                setState(() {
                                  searchRes = Firestore.instance
                                      .collection(DatabaseName)
                                      .orderBy('likes', descending: true)
                                      .where('searchTerm',
                                          isEqualTo: text.toUpperCase())
                                      .snapshots();
                                  //print(docs.documents.length);
                                });
                              },
                            ),
                          ),
                          ResponsiveContainer(
                              heightPercent: 50,
                              widthPercent: 100,
                              child: StreamBuilder(
                                stream: searchRes,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData)
                                    return Center(child: Text(''));
                                  else
                                    return ListView.builder(
                                      itemCount: snapshot.data.documents.length,
                                      itemBuilder: (context, index) {
                                        return _buildListViewTile(
                                            snapshot.data.documents[index]);
                                      },
                                    );
                                },
                              ))
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: ResponsiveContainer(
                        heightPercent: 100,
                        widthPercent: 100,
                        child: ListView(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(bottom: 15),
                              child: TextField(
                                onSubmitted: (v) {
                                  FocusScope.of(context).requestFocus(focusDef);
                                },
                                textInputAction: TextInputAction.next,
                                controller: _textTerm,
                                decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(8),
                                    labelText: 'Term',
                                    icon: Icon(Icons.subject)),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(bottom: 15),
                              child: TextField(
                                onSubmitted: (v) {
                                  FocusScope.of(context).requestFocus(focusExp);
                                },
                                focusNode: focusDef,
                                textInputAction: TextInputAction.next,
                                controller: _textDef,
                                decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(8),
                                    labelText: 'Definition',
                                    icon: Icon(MaterialIcons.getIconData(
                                        'description'))),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(bottom: 15),
                              child: TextField(
                                onSubmitted: (v) {
                                  FocusScope.of(context).requestFocus(focusSub);
                                },
                                focusNode: focusExp,
                                textInputAction: TextInputAction.next,
                                controller: _textExp,
                                decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(8),
                                    labelText: 'Example',
                                    icon: Icon(Icons.info_outline)),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(bottom: 15),
                              child: TextField(
                                onSubmitted: (b) => FocusScope.of(context).unfocus(),
                                focusNode: focusSub,
                                textInputAction: TextInputAction.done,
                                controller: _textSub,
                                decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(8),
                                    labelText: 'Submitted By',
                                    icon: Icon(
                                        SimpleLineIcons.getIconData('user'))),
                              ),
                            ),
                            RaisedButton(
                              color: Colors.teal,
                              textColor: Colors.white,
                              child: Text('Submit'),
                              onPressed: () {
                                if (_textTerm.text.isEmpty ||
                                    _textSub.text.isEmpty ||
                                    _textExp.text.isEmpty ||
                                    _textDef.text.isEmpty) {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Platform.isAndroid
                                            ? AlertDialog(
                                                title: Text('Missing fields'),
                                                content: Text(
                                                    'Provide all necessary information, please.'),
                                              )
                                            : CupertinoAlertDialog(
                                                title: Text('Missing fields'),
                                                content: Text(
                                                    'Provide all necessary information, please.'),
                                              );
                                      });
                                  return;
                                }

                                Firestore.instance
                                    .collection(PendingDatabaseName)
                                    .document()
                                    .setData({
                                  'term': _textTerm.text,
                                  'desc': _textDef.text,
                                  'example': _textExp.text,
                                  'submittedBy': "@" + _textSub.text,
                                  'searchKey': _textTerm.text[0].toUpperCase(),
                                  'searchTerm': _textTerm.text.toUpperCase(),
                                  'likes': 0
                                });
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Platform.isAndroid
                                          ? AlertDialog(
                                              title:
                                                  Text('Submition successful'),
                                              content: Text(
                                                  'The term has been submitted and awaiting approval, Thank you for your collaboration.'),
                                            )
                                          : CupertinoAlertDialog(
                                              title:
                                                  Text('Submition successful'),
                                              content: Text(
                                                  'The term has been submitted and awaiting approval, Thank you for your collaboration.'),
                                            );
                                    });
                                _textTerm.text = "";
                                _textDef.text = "";
                                _textExp.text = "";
                                _textSub.text = "";
                              },
                            ),
                          ],
                        )),
                  ),
                  StaticalObject.bookmark.length == 0
                      ? Center(
                          child: Text('No Data'),
                        )
                      : ResponsiveContainer(
                          heightPercent: 100,
                          widthPercent: 100,
                          child: ListView.builder(
                              itemCount: StaticalObject.bookmark.length,
                              itemBuilder: (context, index) =>
                                  _buildListViewBookmark(
                                      StaticalObject.bookmark.keys
                                          .elementAt(index),
                                      StaticalObject.bookmark[StaticalObject
                                          .bookmark.keys
                                          .elementAt(index)]))),
                ],
              ),
              Visibility(
                visible: rand,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      rand = !rand;
                    });
                  },
                  child: ResponsiveContainer(
                    heightPercent: 100,
                    widthPercent: 100,
                    child: Opacity(
                        opacity: 0.6,
                        child: Container(
                          color: Colors.black,
                        )),
                  ),
                ),
              ),
              Visibility(
                visible: rand,
                child: Center(
                    child: Container(
                  height: 190,
                  width: double.maxFinite,
                  child: Container(
                      color: Colors.grey[650],
                      child: Stack(
                        children: <Widget>[
                          Container(
                            child: ListView.builder(
                              itemCount: 1,
                              itemBuilder: (context, index) {
                                return randomRes == null
                                    ? ListView()
                                    : _buildListViewTile(randomRes);
                              },
                            ),
                          )
                        ],
                      )),
                )),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          getRandom();
        },
        child: Icon(
          Ionicons.getIconData('ios-shuffle'),
          size: 30,
        ),
      ),
    );
  }
}
