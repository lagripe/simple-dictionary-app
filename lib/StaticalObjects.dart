import 'package:astaray/CardObject.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class StaticalObject {
  // Load from cache
  static Map<String, CardObject> bookmark = Map<String, CardObject>();
  static List<String> likes = List<String>();
  static SharedPreferences prefs;
  static String DatabaseName = 'data';
  static initCache() async {
    if(bookmark.length != 0 || likes.length != 0)
    return;
    prefs = await SharedPreferences.getInstance();
    //prefs.clear();
    likes = prefs.getStringList('likes') ?? List<String>();
    List<String> book = prefs.getStringList('bookmark');
    bookmark = book == null ? Map<String, CardObject>() : getBookmarkDocs(book);
    //print(getBookmarkDocs(book).length);
  }

  static setLikes() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likes', likes);
  }

  static setBookmark() async {
    prefs = await SharedPreferences.getInstance();
    prefs.setStringList('bookmark', saveDocsIDS(bookmark));
    
  }

  static List<String> saveDocsIDS(Map<String, CardObject> bookmark) {
    List<String> out = List<String>();
    for (var item in bookmark.entries) {
      out.add(item.key);
    }
    return out;
  }

  static Map<String, CardObject> getBookmarkDocs(List<String> IDs) {
    Map<String, CardObject> out = Map<String, CardObject>();
    for (var item in IDs) {
      
      Firestore.instance.collection(DatabaseName).document(item.toString()).get().then((doc){
        if(!doc.data.isEmpty){
          out[item] = CardObject(doc.data['term'].toString(),
          doc.data['desc'].toString(),
          doc.data['likes'],
          doc.data['id'].toString(),
          doc.data['example'].toString(),
          doc.data['submittedBy'].toString()
          );
        }
      });
    }
    return out;
  }
}
