import 'package:dating_app_dashboard/dialogs/progress_dialog.dart';
import 'package:dating_app_dashboard/models/app_model.dart';
import 'package:dating_app_dashboard/widgets/default_button.dart';
import 'package:dating_app_dashboard/widgets/default_card_border.dart';
import 'package:dating_app_dashboard/widgets/show_scaffold_msg.dart';
import 'package:flutter/material.dart';

class SendMessage extends StatefulWidget {
  const SendMessage({Key? key}) : super(key: key);

  @override
  _SendMessageState createState() => _SendMessageState();
}

class _SendMessageState extends State<SendMessage> {
  // Variables
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Message"),
      ),
      key: _scaffoldKey,
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            elevation: 10.0,
            shape: defaultCardBorder(),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text("Send Message",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  const Text("Send message to all users",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 22),

                  /// Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        /// message field
                        TextFormField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              labelText: "Text message",
                              hintText: "Write message",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              prefixIcon: const Icon(Icons.mail_outline)),
                          keyboardType: TextInputType.emailAddress,
                          validator: (message) {
                            // Basic validation
                            if (message?.isEmpty ?? true) {
                              return "Please type message";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        ///Send message button
                        SizedBox(
                          width: double.maxFinite,
                          child: DefaultButton(
                            child: const Text("Send message",
                                style: TextStyle(fontSize: 18)),
                            onPressed: () async {
                              /// Validate form
                              if (_formKey.currentState!.validate()) {
                                // instance
                                final _pr = ProgressDialog(context);
                                // Show processing dialog
                                _pr.show("Sending...");

                                await AppModel().sendMessage2AllUser(
                                  message: _messageController.text,
                                  onError: () {
                                    showScaffoldMessage(
                                        context: context,
                                        scaffoldkey: _scaffoldKey,
                                        message:
                                        "Error Sending Message!");
                                  },
                                  onSuccess: () {},
                                );
                                // close progress
                                _pr.hide();
                                // Clear text
                                _messageController.clear();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
