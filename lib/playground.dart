import 'package:flutter/material.dart';

class FocusVisibilityDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('hello');
    return new Center(
      child: new RaisedButton(
        onPressed: () => _showDialog(context),
        child: new Text("Push Me"),
      ),
    );
  }

  _showDialog(BuildContext context) async {
    await showDialog<String>(
      context: context,
      builder: (_) {
        print('sup');
        return new AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: new Row(
            children: <Widget>[
              new Expanded(
                child: new TextFormField(
                  autofocus: true,
                  decoration:
                      new InputDecoration(labelText: 'Full Name', hintText: 'eg. John Smith'),
                ),
              )
            ],
          ),
          actions: <Widget>[
            new FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            new FlatButton(
                child: const Text('OPEN'),
                onPressed: () {
                  Navigator.pop(context);
                })
          ],
        );
      },
    );
  }
}
