class CardObject {

  String term,description,id,example,submittedBy;
  int likes;
  CardObject.empty();
  CardObject(this.term,this.description,this.likes,this.id,this.example,this.submittedBy);
  

  Map<String, dynamic> toJson() => {
    'term' : term,
    'description' : description,
    'likes' : likes,
    'example' : example,
    'likes' : likes,
    'id' : id
  };
}