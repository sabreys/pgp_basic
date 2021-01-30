import 'dart:async';
import 'dart:convert';
import 'dart:html' as webFile;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown_editable_textinput/format_markdown.dart';
import 'package:markdown_editable_textinput/markdown_text_input.dart';
import 'package:oktoast/oktoast.dart';
import 'package:openpgp/model/bridge.pb.dart';

import 'package:openpgp/openpgp.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'BASIC PGP',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  KeyPair keypair=KeyPair();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String description = '';
  String key1 = "Paste Your key or generate one.";
  String key2 = "Paste Your key or generate one.";

  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Theme(
        data: ThemeData(
          primaryColor: const Color(0xFF2B3409),
          accentColor: const Color(0xFF71881B),
          cardColor: const Color(0xFFF7FBEA),
          textTheme: const TextTheme(bodyText2: TextStyle(fontSize: 20)),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('PGP DIARY TEST AREA'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 100),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                              height: 200,
                              width: MediaQuery.of(context).size.width / 2 - 50,
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  child: TextField(
                                    controller: controller1,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                  ),
                                ),
                              ),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 8,
                                  )),
                            ),
                            Container(
                              height: 200,
                              width: MediaQuery.of(context).size.width / 2 - 50,
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  child: TextField(
                                    controller: controller2,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                  ),
                                ),
                              ),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 8,
                                  )),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FlatButton(
                              onPressed: () async {
                                print("sa");
                                var keyOptions = KeyOptions()..rsaBits = 1024;
                                var keyPair = await OpenPGP.generate(
                                    options: Options()
                                      ..name = 'test'
                                      ..email = 'test@test.com'
                                      ..passphrase = "sifre"
                                      ..keyOptions = keyOptions);


                                setState(() {
                                  widget.keypair = keyPair;
                                  controller1.text=keyPair.publicKey;
                                  controller2.text=keyPair.privateKey;
                                  key1 = keyPair.publicKey;
                                  key2 = keyPair.privateKey;
                                });
                              },
                              child: Text("Generate Keys")),
                        ),
                        FlatButton(
                            onPressed: download_key,
                            child: Text("Download Keys ")),
                        SizedBox(height: 20,),
                        MarkdownTextInput(
                          (String value) =>  description = value,
                          description,
                          label: 'Description',
                          maxLines: 3,
                        ),
                     /*   Padding(
                          padding: const EdgeInsets.only(top: 10,left: 10),
                          child: MarkdownBody(
                            data: description,
                            shrinkWrap: true,
                          selectable: true,),
                        ),*/

                        SizedBox(height: 10,),
                        SelectableText(description,),
                        SizedBox(height: 10,),
                        RaisedButton(
                          onPressed: () async {
                            widget.keypair.publicKey=controller1.text;
                            widget.keypair.privateKey=controller2.text;

                            if (!widget.keypair.hasPublicKey() || widget.keypair.publicKey== "") {
                              setState(() {
                                null_key_toast();
                              });
                            } else {

                              var result = await OpenPGP.encrypt(
                                  description, widget.keypair.publicKey);
                              setState(() {
                                description = result;
                              });
                            }
                          },
                          child: Text("Encrypt"),
                        ),
                        RaisedButton(
                          onPressed: () async {
                            widget.keypair.publicKey=controller1.text;
                            widget.keypair.privateKey=controller2.text;
                            if (!widget.keypair.hasPrivateKey()|| widget.keypair.privateKey== "") {
                              null_key_toast();
                              return;
                            }

                            var result = await OpenPGP.decrypt(description,
                                widget.keypair.privateKey, "sifre");
                            setState(() {
                              description = result;
                            });
                          },
                          child: Text("Decrypt"),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void null_key_toast() {
    showToast(
      'You need to have a key. please generate and save one ',
      position: ToastPosition.bottom,
      backgroundColor: Color(0xFFEE507A),
      radius: 13.0,
      textStyle: TextStyle(fontSize: 18.0, color: Colors.white),
      animationBuilder: Miui10AnimBuilder(),
    );
  }

  void download_key() {
    if (!(widget.keypair.hasPublicKey() && widget.keypair.hasPrivateKey()) || widget.keypair.publicKey== "" || widget.keypair.privateKey== "") {
      null_key_toast();
      return;
    }
    var blob =
        webFile.Blob([widget.keypair.privateKey], 'text/plain', 'native');

    var anchorElement = webFile.AnchorElement(
      href: webFile.Url.createObjectUrlFromBlob(blob).toString(),
    )
      ..setAttribute("download", "private_key.txt")
      ..click();

    var blob2 =
        webFile.Blob([widget.keypair.publicKey], 'text/plain', 'native');

    var anchorElement2 = webFile.AnchorElement(
      href: webFile.Url.createObjectUrlFromBlob(blob2).toString(),
    )
      ..setAttribute("download", "public_key.txt")
      ..click();
  }
}
