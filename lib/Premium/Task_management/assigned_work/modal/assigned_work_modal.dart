// In file: assigned_work/modal/assigned_work_modal.dart

// This is the main class for each task item.
class AssignedTask {
  final int id;
  final int employeeId; // In JSON, this is a String e.g. "204"
  final String? checkIn;
  final String? checkout;
  final String? task;
  final String? remarks;
  final String? status;
  final String? createdAt;
  final Employee? employee; // This is a nested object
  final Customer? customer; // This nested object can be null

  AssignedTask({
    required this.id,
    required this.employeeId,
    this.checkIn,
    this.checkout,
    this.task,
    this.remarks,
    this.status,
    this.createdAt,
    this.employee,
    this.customer,
  });

  // This updated factory constructor now perfectly matches your API response.
  factory AssignedTask.fromJson(Map<String, dynamic> json) {
    return AssignedTask(
      id: json['id'],
      employeeId: json['employee_id'],
      checkIn: json['check_in'],
      checkout: json['checkout'],
      task: json['task'],
      remarks: json['remarks'],
      status: json['status'],
      createdAt: json['check_in'],
      // Safely parse the nested 'employee' object.
      employee:
          json['employee'] != null ? Employee.fromJson(json['employee']) : null,
      // Safely parse the nested 'customer' object, which can sometimes be null.
      customer:
          json['customer'] != null ? Customer.fromJson(json['customer']) : null,
    );
  }
}

// Model for the nested "employee" object.
class Employee {
  final int employeeId;
  final String? firstName;
  final String? lastName;
  final String? email;

  Employee({
    required this.employeeId,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employee_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
    );
  }
}

// Model for the nested "customer" object.
class Customer {
  final int id;
  final String? companyName;
  final String? contactPerson;
  final String? contactNumber;

  Customer({
    required this.id,
    this.companyName,
    this.contactPerson,
    this.contactNumber,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      companyName: json['company_name'],
      contactPerson: json['contact_person'],
      contactNumber: json['contact_number'],
    );
  }
}
