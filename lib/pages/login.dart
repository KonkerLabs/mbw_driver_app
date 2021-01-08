import 'package:flutter/material.dart';

import './busline.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginState createState() => new LoginState();

}

class LoginState extends State<LoginPage> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _driver;
  BusLinePage driverPage = new BusLinePage('');

  @override
  Widget build(BuildContext context) {
    return new Material(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.always,
        onChanged: () {
          Form.of(primaryFocus.context).save();
        },
        child: SingleChildScrollView(child: Column(
          children: [
            Image(image:AssetImage('./images/mybusway-logo.png'), height:250),
            Text("nome do motorista"),
            TextFormField(
              initialValue: '',
              textAlign: TextAlign.center,
              validator: (value) {
                print('validating name $value');
                return (value != null && value.isEmpty) ? 'nome não pode ser vazio' : null;
              },
              onSaved: (String value) {
                setState(() {
                  _driver = value;
                  // print('save $_driver x $value');
                }); }
            ),
            ElevatedButton(
                child: Text("Entrar"),
                onPressed: () {
                  if (_driver != null && _driver.isNotEmpty) {
                    print('RockIt $_driver');
                    this.driverPage.setDriver(_driver);
                    Navigator.push(context, new MaterialPageRoute(builder: (ctx) => this.driverPage));
                  }
                },
              ),
            TextFormField(
              initialValue: this.driverPage != null ? this.driverPage.getBaseUrl(): '',
              textAlign: TextAlign.left,
              onSaved: (String value) {
                setState(() {
                  this.driverPage.setBaseUrl((value));
                });
              }
              ,),
            Padding(padding:EdgeInsets.only(top:40), child:Image(image:AssetImage('./images/RDX_ENERGY_URBAN_VERMELHO.png'), height:100)),
          ],)
      ))
    );
  }

}