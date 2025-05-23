import 'package:flutter/material.dart';

class AttendanceDetails extends StatefulWidget {
  const AttendanceDetails({super.key});

  @override
  State<AttendanceDetails> createState() => _AttendanceDetailsState();
}

class _AttendanceDetailsState extends State<AttendanceDetails> {
  bool isLoadingInit = false;
  List attendanceHistory = [];
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    isLoadingInit = args['isLoading'];
    attendanceHistory = args['attendance_history'] ?? [];
    print(args['attendance_history']);
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Details'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body:
          (isLoadingInit || attendanceHistory == [])
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subject Name',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
                      ListTile(
                        title: Text('Attendance'),
                        shape: LinearBorder(
                          side: BorderSide(color: Colors.red, width: 5),
                        ),
                        trailing: Text(
                          '${args['attendance']}%',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                args['attendance'] < 85
                                    ? Colors.red
                                    : Colors.green,
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text('Present'),
                        trailing: Text(
                          attendanceHistory
                              .where((row) => row[3] == "Present")
                              .length
                              .toString(),
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ),
                      ListTile(
                        title: Text('Absent'),
                        trailing: Text(
                          attendanceHistory
                              .where((row) => row[3] == "Absent")
                              .length
                              .toString(),
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
                      ListTile(
                        title: Text('Total Classes'),
                        trailing: Text(
                          attendanceHistory.length.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            // color: ,
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          'Attendance History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: TableBorder.all(width: 0.3),
                          headingRowHeight: 40,
                          columns: [
                            DataColumn(
                              label: Text(
                                'SL NO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'DATE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'TIME',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'STATUS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          rows: List.generate(attendanceHistory.length, (
                            index,
                          ) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '${attendanceHistory[index][0]}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${attendanceHistory[index][1]}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${attendanceHistory[index][2]}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${attendanceHistory[index][3]}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          attendanceHistory[index][3] ==
                                                  'Present'
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
