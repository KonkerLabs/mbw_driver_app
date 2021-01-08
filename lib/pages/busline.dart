import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BusLinePage extends StatefulWidget {

  String _driver;
  BusLineState _state;

  BusLinePage(String driver) {
    this._driver = driver;
    this.createState();
  }

  @override
  BusLineState createState() {
    BusLineState state = new BusLineState(); 
    state._driver = this._driver;
    this._state = state;

    return state;
  }

  void setDriver(String driver) {
    this._driver = driver;
    if (this._state == null) {
      createState();
    }  
    
    
  }

  String getBaseUrl() {
    return this._state != null ? this._state.baseUrl : '';
  }
  void setBaseUrl(String url) {
    this._state.baseUrl = url;
  }


}

class FetchDataException implements Exception {
 final _message;
 FetchDataException([this._message]);

String toString() {
if (_message == null) return "Exception";
  return "Exception: $_message";
 }
}


class Log {
  String _line;
  String _car;
  int _ts;

  Log.fromJson(Map<String, dynamic> data) {
    _line = data['line'];
    _car = data['car'];
    _ts = data['ts'];
  }

}

class Line {
  String name;
  String color;

  Line({this.name, this.color});

  factory Line.fromJson(Map<String, dynamic> data) {
    print(data);
    return Line(name:data["name"], color:data['color']);
  }

  String toString() {
    return '(name:$name, color:$color)';
  }
}

class Car {
  String id;
  String name;

  Car({this.id, this.name});

  factory Car.fromJson(Map<String, dynamic> data) {
    return Car(name:data['name'], id:data['id']);
  }

  String toString() => '(name:$name, id:$id)';
}

class BusLineState extends State<BusLinePage> {

  bool isProduction = bool.fromEnvironment('dart.vm.product');
  String baseUrl;
  String _driver;
  Line _line;
  Car _car = null;
  Car _oldCar = null;
  List<Line> _lines = []; // [Line(name:'Amarelo', color:'yellow'), Line(name:'Verde', color:'green'), Line(name:'Rosa', color:'pink'), Line(name:'Azul', color:'blue')];
  List<Car> _cars = [];
  // Map<String, String> _images = {'yellow': 'Amarelo', 'green': 'Verde', 'pink':'Rosa', 'blue':'Azul'};

  List<Log> log = new List<Log>();

  Future<List<Line>> fetchLines() async {
    List<Line> lines;
    var response = await http.get('$baseUrl/lines');

    print(response.body);

    lines=(jsonDecode(response.body) as List).map((i) =>
                  Line.fromJson(i)).toList();

    return lines;

  }

  Future<List<Car>> fetchCars() async {
    List<Car> cars;
    var response = await http.get('$baseUrl/buses');
    cars = (jsonDecode(response.body) as List).map((i) => Car.fromJson(i)).toList();
    return cars;
  }

   @override
  void initState() {
    super.initState();
    baseUrl = isProduction ? 'http://projac.mybusway.com:8080' : 'http://10.0.2.2:8080';
    // baseUrl = 'http://projac.mybusway.com:8080';
    print('loading data from server HTTP - ${baseUrl}');
    try {
      fetchLines().then((value) {
        setState(() {
          _lines = value; 
          print('loaded lines');
          print(value);
        });
      });
      fetchCars().then((value) {
        setState(() {
          print('loaded buses');
          _cars = value;
        });
      });

    } on Exception catch(e) {
        print('error caught: $e');
      }
  }

  Future saveLog(String car, String line, String user, int ts) async {
    var response = await http.get('$baseUrl/vehicles/$car/use/$line/by/$user/on/$ts');
    print(response.body);
  }
    

  void pushInfo() { 
    if (_car != null && _line != null) {
      print('setting ${_car.name} with line ${_line.name}');
      int ts = DateTime.now().millisecondsSinceEpoch;
      log.insert(0, new Log.fromJson({'car':_car.name, 'line':_line.name, 'ts':ts}));

      // send request to server to allow configuration of car 
      saveLog(_car.name, _line.name, _driver, ts);

    } else {
      if (_oldCar != null && _line != null) {
        // dissociate car 
        int ts = DateTime.now().millisecondsSinceEpoch;
        log.insert(0, new Log.fromJson({'car':'${_oldCar.name} (*)', 'line':_line.name, 'ts':ts}));

        // send request to server to allow configuration of car 
        saveLog(_oldCar.name, '<>', _driver, ts);

      } else {
        print('OOPS: ${_car?.name ?? 'missing car'} with line ${_line?.name ?? 'missing line'}');
      }
      
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: new AppBar(title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text('MyBusWay @ Driver'), Image(image:AssetImage('./images/rdx-logo.png'), height:20)])),
      body: SingleChildScrollView(child: Center(
              child: Column(
                children: [
                  Text(' Motorista ', style: TextStyle(fontWeight: FontWeight.bold, fontSize:20, color: Colors.grey),),
                  Text(_driver, style: TextStyle(fontWeight: FontWeight.bold, fontSize:30),),
                  Text(' Linha ', style: TextStyle(fontWeight: FontWeight.bold, fontSize:20, color: Colors.grey),),
                  Wrap(children: _lines.map((v) {
                    return Padding(
                      padding:EdgeInsets.all(8), 
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(v == _line ? Colors.lightGreen : Colors.white),
                          foregroundColor: MaterialStateProperty.all<Color>(v == _line ? Colors.white : Colors.black)),
                        child:Column(children: [Image(image: AssetImage("images/symbol-${v.color}.png"), width: 50,), Text(v.name)],), 
                        onPressed: () {
                          setState(() {
                            _line = v;
                            _car = null;
                            _oldCar = null;
                            print('setting line as $v');
                            pushInfo();
                          });
                        }
                      )
                    );
                  }).toList()
                  ),
                  Text(' # do Veículo ', style: TextStyle(fontWeight: FontWeight.bold, fontSize:20, color: Colors.grey),),
                  Wrap(children: _cars.map((car) {
                    return Padding(
                      padding: EdgeInsets.all(8),
                      child: ElevatedButton(
                        style: car == _car ? ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.green)) : null,
                        child: Text('${car.name}'),
                        onPressed: () {
                          setState(() {
                            if (car == _car) {
                              // dissociate this car from the line
                              _oldCar = _car;
                              _car = null;
                              print('dissociate car from line');
                            } else {
                              // associate this car with line
                              _car = car;
                              print('setting car as ${car.name}');
                            }
                            pushInfo();
                          });
                        })
                    );
                  }).toList(),),
                  Text(' Histórico ', style: TextStyle(fontWeight: FontWeight.bold, fontSize:20, color: Colors.grey),),
                  SingleChildScrollView(child:DataTable(
                      
                      columns: [DataColumn(label: Text('dt/hr')), DataColumn(label:Text('veiculo')), DataColumn(label:Text('linha'))],
                      rows:log.map((data) {
                        var ts = DateTime.fromMillisecondsSinceEpoch(data._ts);
                        return DataRow(cells:[
                          DataCell(Text(ts.toLocal().toString())),
                          DataCell(Text('${data._car}')),
                          DataCell(Text(data._line))
                        ]);
                      }).toList()
                    )
                    )
                  
                ]
              )
            )
    )
    );
  }

}