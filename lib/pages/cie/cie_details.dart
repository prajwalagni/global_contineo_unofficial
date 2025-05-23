import 'package:flutter/material.dart';

class CieDetailsPage extends StatefulWidget {
  const CieDetailsPage({super.key});

  @override
  State<CieDetailsPage> createState() => _CieDetailsPageState();
}

class _CieDetailsPageState extends State<CieDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    Map<String, String> data = args['data'];
    List<String> headers = data.keys.toList();
    List<String> values = data.values.toList();
    print(headers);
    print(headers.length);
    print(values);
    // print(int.parse(values[5].replaceAll('%', '')));
    return Scaffold(
      appBar: AppBar(
        title: Text('CIE Details'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject Name',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${args['subject_code']} - ${args['subject_name']}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                itemCount: headers.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(headers[index]),
                    trailing: Text(
                      values[index],
                      style:
                          headers[index].toLowerCase() == 'attendance'
                              ? TextStyle(
                                fontSize: 15,
                                color:
                                    int.parse(values[index].replaceAll('%', '')) < 85
                                        ? Colors.red
                                        : Colors.green,
                              )
                              : TextStyle(fontSize: 15),
                    ),
                  );
                },
              ),
              // ListTile(
              //   title: Text('Attendance'),
              //   shape: LinearBorder(
              //     side: BorderSide(color: Colors.red, width: 5),
              //   ),
              //   trailing: Text(
              //     '${args['attendance']}%',
              //     style: TextStyle(
              //       fontSize: 16,
              //       color: args['attendance'] < 85 ? Colors.red : Colors.green,
              //     ),
              //   ),
              // ),
              // ListTile(
              //   title: Text('CIE 1'),
              //   trailing: Text(
              //     '${args['cie_1']}',
              //     style: TextStyle(fontSize: 15),
              //   ),
              // ),
              // ListTile(
              //   title: Text('CIE 2'),
              //   trailing: Text(args['cie_2'], style: TextStyle(fontSize: 15)),
              // ),
              // ListTile(
              //   title: Text('CIE 3'),
              //   trailing: Text(args['cie_3'], style: TextStyle(fontSize: 15)),
              // ),
              // ListTile(
              //   title: Text('Final CIE'),
              //   trailing: Text(
              //     '${args['final_cie']}',
              //     style: TextStyle(fontSize: 15),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
