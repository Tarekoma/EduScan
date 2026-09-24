<div align="center">

# 🏫 Attendance Management System

### Smart Digital Attendance Platform Built with Flutter & Firebase

**Modernizing school attendance through secure QR-based check-in, real-time attendance monitoring, role-based access, and parent communication.**

</div>

---

## 📖 Overview

**Attendance Management System** is a digital attendance platform developed using **Flutter and Firebase** to replace traditional paper-based attendance systems.

The application provides dedicated interfaces for **Managers, Supervisors, Security Staff, and Parents**, enabling secure attendance recording, attendance monitoring, and easy access to attendance history.

The system uses **QR Code scanning** as the primary method for recording attendance.

> 🎬 **Application Demo:** **[Watch Video Here](https://1drv.ms/v/c/47438efdb3ee2559/IQBfEJQWpmMqQZ7obSjuo3QMARQ1iACrELRtFV0sYVLuVa4?e=bMKzg2)**

> 📱 **Platform:** Flutter Web / Mobile

> ☁️ **Backend:** Firebase

---

## 📸 Application Preview

<div align="center">

| Manager Dashboard                                                | Security                                                | Parent                                                |
| ---------------------------------------------------------------- | ------------------------------------------------------- | ----------------------------------------------------- |
|<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/4df1dd26-f4a3-4418-b001-180de69f1140"/>|<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/b0e43d9e-e423-4b1e-a8d0-697b6b331efd"/>|<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/ce88be3b-5c34-4544-96df-dc40b4435a00"/>|

<br>

| Students                                                  | Users                                                     | Attendance History                                                |
| --------------------------------------------------------- | --------------------------------------------------------- | ----------------------------------------------------------------- |
|<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/7094d636-c038-40f6-8c60-3d5e45b008f5"/>|<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/a22f56b1-f6b6-4bbf-aea8-df1ab107a34a"/>|<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/d83dca9d-c648-4d1e-88dd-b1921c9570e9"/>|

</div>

---

## 🔍 Problems We Solve

| # | Problem                                                             |
| - | ------------------------------------------------------------------- |
| 1 | Paper-based attendance is difficult to maintain and analyze         |
| 2 | Manual attendance recording is time-consuming                       |
| 3 | Attendance records can be difficult to retrieve and manage          |
| 4 | Parents have limited access to their child's attendance information |
| 5 | Schools need centralized attendance monitoring                      |

---

# ✨ Core Features

## 🛡️ Security Features

| Feature                 | Description                                          |
| ----------------------- | ---------------------------------------------------- |
| 📷 QR Attendance        | Scan student and staff QR codes to record attendance |
| 🕐 Check-In / Check-Out | Record arrival and departure times                   |
| 👤 User Verification    | Validate users before recording attendance           |
| 🚨 Pickup Alerts        | Receive parent pickup requests                       |
| 📞 Staff Contact        | Contact school staff when required                   |

---

## 👨‍💼 Manager Features

* 📊 Attendance Dashboard
* 👥 Student & Staff Management
* ➕ Add Students
* 👮 Manage Security Accounts
* 🔎 Search & Filter Attendance
* 📈 Attendance Statistics
* 📅 View Attendance History

---

## 👨‍💼 Supervisor Features

* 📊 Monitor Attendance
* 👥 View Students & Staff
* 📅 View Attendance History
* 🔎 Search & Filter Records
* 📈 Monitor Attendance Statistics

---

## 👨‍👩‍👧 Parent Features

* 👤 View Child Information
* 🟢 View Attendance Status
* 🔴 View Absence Records
* 🕐 View Check-In / Check-Out Times
* 📅 View Attendance History
* 🚨 Send Pickup Requests

> 🔐 Parents can only access attendance information related to **their own child**.

---

## 📷 QR-Based Attendance

QR Code scanning is the primary attendance workflow.

```text id="3r9y8h"
Student / Teacher
       ↓
Personal QR Code
       ↓
Security Scans QR
       ↓
User Validation
       ↓
Attendance Recorded
       ↓
Firebase Firestore
       ↓
Dashboard Updated
```

This reduces manual data entry and provides a fast and simple attendance process.

---

## 📊 Attendance Dashboard

The dashboard provides a clear overview of attendance data inspired by traditional Excel attendance sheets.

### Dashboard includes:

* 🟢 Present Count
* 🔴 Absent Count
* 👥 Student / Staff Filters
* 🕐 Check-In & Check-Out Times
* 📅 Attendance History
* 🔎 Search & Filtering
* 📈 Attendance Trends

---

## 🚨 Parent Pickup System

Parents can send a pickup request directly through the application.

```text id="5b8x3p"
Parent
  ↓
Pickup Request
  ↓
Firebase
  ↓
Security Application
  ↓
🔔 Alert
  ↓
Security Contacts Teacher
```

This allows the security team to receive and respond to parent pickup requests.

---

# 🔐 Role-Based Access

The system provides different permissions for each user role.

| Role             |    View   | Edit Attendance | Manage Users |
| ---------------- | :-------: | :-------------: | :----------: |
| 👨‍💼 Manager    |     ✅     |        ❌        |       ✅      |
| 👨‍💼 Supervisor |     ✅     |        ❌        |       ❌      |
| 🛡️ Security     |     ✅     |        ✅        |       ❌      |
| 👨‍👩‍👧 Parent  | Own Child |        ❌        |       ❌      |

---

# 🏗️ Architecture

The application follows a **Clean Architecture-inspired structure** with **Cubit** for state management.

```text id="2c7w6k"
Presentation
     │
     ▼
   Cubit
     │
     ▼
  Use Cases
     │
     ▼
 Repository
     │
     ▼
 Data Sources
     │
     ▼
   Firebase
```

The architecture focuses on:

* ♻️ Reusability
* 🧩 Separation of Concerns
* 🧪 Testability
* 🔐 Secure Data Access
* 🚀 Maintainability

---

# 🛠️ Tech Stack

| Technology                  | Usage                     |
| --------------------------- | ------------------------- |
| **Flutter**                 | Application Development   |
| **Dart**                    | Programming Language      |
| **Firebase Authentication** | User Authentication       |
| **Cloud Firestore**         | Database                  |
| **Firebase Security Rules** | Access Control            |
| **Cubit / flutter_bloc**    | State Management          |
| **QR Code**                 | Attendance Identification |
| **Git & GitHub**            | Version Control           |
| **Figma**                   | UI/UX Design              |

---

# 🧪 Testing

The project includes automated testing and Firebase security validation.

| Check                    | Result               |
| ------------------------ | -------------------- |
| `flutter analyze`        | ✅ No issues found    |
| `flutter test`           | ✅ 61/61 passed       |
| `flutter build web`      | ✅ Successfully built |
| Firestore Emulator Tests | ✅ 10/10 passed       |

---

# 🎯 Objectives

* ✅ Replace paper-based attendance
* ✅ Reduce manual attendance work
* ✅ Improve attendance management
* ✅ Provide centralized attendance monitoring
* ✅ Implement secure role-based access
* ✅ Give parents access to their child's attendance
* ✅ Provide fast QR-based attendance
* ✅ Improve communication between parents and school staff

---

# 🌍 Applications

The system can be adapted for:

* 🏫 Schools
* 🎓 Educational Institutions
* 🏢 Training Centers
* 👨‍🏫 Educational Academies
* 🏫 Private Education Centers

---

# 👨‍💻 Developer

<div align="center">

### **Tarek Omar Mahmoud**

**Flutter Developer · Data Analyst · AI Enthusiast**

Built with **Flutter & Firebase** 🇪🇬

</div>

---

<div align="center">

# ⭐ Attendance Management System

**Digital Attendance · QR Scanning · Firebase · Analytics · Parent Monitoring**

Made with ❤️ using **Flutter & Firebase** 🇪🇬

</div>
