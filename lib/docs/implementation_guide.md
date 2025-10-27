# API Endpoints Implementation Guide

## 📋 **API Endpoints Overview**

### **1. Authentication Endpoint**
- **URL**: `https://mateib.ro/idexauth.php`
- **Method**: POST
- **Purpose**: User login authentication
- **Implementation**: Already implemented in `ApiService.login()`

### **2. Location List Endpoint**
- **URL**: `https://mateib.ro/idexroluri.php`
- **Method**: POST
- **Purpose**: Get list of locations for dropdown
- **Implementation Location**: Location selection screen

### **3. Search Roles Endpoint**
- **URL**: `https://mateib.ro/idexroluri.php`
- **Method**: POST
- **Purpose**: Search for roles by location and address
- **Implementation Location**: Search results screen

### **4. Update Reading Endpoint**
- **URL**: `https://mateib.ro/idexadauga.php`
- **Method**: POST
- **Purpose**: Update meter reading values
- **Implementation Location**: Meter reading update screen

## 🎯 **Screen Flow Implementation**

### **Screen 1: Location Selection**
- **Component**: Dropdown with locations
- **Position**: Sticky up (top of screen)
- **Data**: `localit` array with `id_loc` and `loc`
- **API Call**: `idexroluri.php`

### **Screen 2: Address Search**
- **Component**: Form with address fields
- **Fields**: 
  - `id_loc` (from location dropdown)
  - `str` (street name)
  - `nr_dom` (house number)
  - `rol` (role number)
- **API Call**: `idexroluri.php`

### **Screen 3: Search Results**
- **Component**: List of found roles
- **Data Structure**:
  - `count_roles`: Number of results
  - `date`: Array of role objects
  - Each role contains: `id_rol`, `rol`, `pers`, `addr`, `tax`

### **Screen 4: Meter Reading Update**
- **Component**: Form for each tax item
- **Fields**:
  - `id_rol`, `id_tip_taxa`, `id_tax2rol`, `id_tax2bord`
  - `val_new` (new reading value)
  - `data_citire_new` (reading date)
  - `tip_citire_old` (reading type)
- **API Call**: `idexadauga.php`

## 📊 **Data Models Needed**

### **Location Model**
```dart
class Location {
  int idLoc;
  String loc;
}
```

### **Person Model**
```dart
class Person {
  String nume;
  String pren;
  int? cnp;
  int tipPers; // 1 = PF, 2 = PJ
}
```

### **Address Model**
```dart
class Address {
  String loc;
  String str;
  String nrDom;
}
```

### **Tax Model**
```dart
class Tax {
  int idTipTaxa;
  int idTax2rol;
  int idTax2bord;
  String numeTaxa;
  String unitMasura;
  int valOld;
  String dataCitireOld;
  String tipCitireOld;
  int valNewP;
  int valNewE;
}
```

### **Role Model**
```dart
class Role {
  int idRol;
  int rol;
  Person pers;
  Address addr;
  List<Tax> tax;
}
```

## 🔧 **Business Logic Notes**

### **Reading Types (tip_citire_old)**
- **C**: Citire (default) - Manual reading
- **E**: Estimat - Estimated reading
- **P**: Pausal - Fixed amount
- **F**: Fara facturare - No billing
- **X**: Neutilizat inca - Not used yet

### **Automatic Value Selection**
- If `tip_citire_old` is **P** or **E**, automatically use `val_new_p` or `val_new_e` values in `val_new`

### **Error Handling**
- If `err = 1`, display `msg_err` message on screen
- If `err = 0`, operation successful

## 🚀 **Implementation Priority**

1. **High Priority**: Location dropdown and search functionality
2. **Medium Priority**: Results display and role selection
3. **Low Priority**: Meter reading update forms

## 📱 **UI Components Needed**

- Location dropdown (sticky up position)
- Address input form
- Search results list
- Meter reading form
- Error message display
- Loading indicators
- Success/error notifications
