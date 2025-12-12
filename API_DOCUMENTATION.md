# API Documentation for Mobile (Flutter) Application

**Base URL:** `https://your-domain.com/api` (or `http://localhost:3000/api` for development)

**Authentication:** Most endpoints require authentication via JWT token. Include the token in the `Authorization` header:
```
Authorization: Bearer <accessToken>
```

Alternatively, the token can be sent in a cookie named `accessToken` (for web browsers).

**Content-Type:** `application/json` for all requests (except file uploads)

---

## 📱 Response Format

All API responses follow this format:

```json
{
  "success": true,
  "data": { /* response data */ },
  "message": "Optional success message"
}
```

Error responses:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message"
  }
}
```

---

## 🔐 Authentication Endpoints

### 1. Login
**POST** `/auth/login`

**Description:** Authenticate user or recycling unit

**Request Body:**
```json
{
  "mobile": "string (min 5 characters)",
  "password": "string (min 4 characters)"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "accessToken": "jwt_token_here",
    "user": {
      "id": "string",
      "fullName": "string",
      "mobile": "string",
      "role": "USER|ADMIN",
      "totalPoints": 0
    }
    // OR for recycling units:
    "recyclingUnit": {
      "id": "string",
      "unitName": "string",
      "phoneNumber": "string",
      "unitOwnerName": "string",
      "role": "RECYCLING_UNIT",
      "status": "PENDING|APPROVED|REJECTED"
    }
  }
}
```

**Error Responses:**
- `400` - Validation error
- `401` - Invalid credentials

---

### 2. Check Authentication
**GET** `/auth/check`

**Description:** Verify if user is authenticated

**Headers:** `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "authenticated": true,
    "role": "USER|ADMIN|RECYCLING_UNIT"
  }
}
```

**Error Responses:**
- `401` - Not authenticated

---

### 3. Check Admin Authentication
**GET** `/auth/check-admin`

**Description:** Verify if user is admin

**Headers:** `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "authenticated": true
  }
}
```

**Error Responses:**
- `401` - Not authenticated
- `403` - Not admin

---

### 4. Logout
**POST** `/auth/logout`

**Description:** Logout current user

**Headers:** `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {}
}
```

---

## 📤 File Upload

### Upload Image
**POST** `/upload/image`

**Description:** Upload an image file

**Content-Type:** `multipart/form-data`

**Request:**
- `file` (File): Image file (JPEG, PNG, WebP)
  - Max size: 8MB
  - Allowed types: `image/jpeg`, `image/jpg`, `image/png`, `image/webp`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "url": "/uploads/upload-1234567890-123456789.jpg",
    "filename": "upload-1234567890-123456789.jpg"
  },
  "message": "File uploaded successfully"
}
```

**Error Responses:**
- `400` - No file provided, invalid file type, or file too large
- `500` - Upload failed

**Note:** The returned `url` is a relative path. Prepend your base URL to get the full image URL.

---

## 👤 User Endpoints (Public/Mobile)

### Register User
**POST** `/users/register`

**Description:** Register a new user

**Request Body:**
```json
{
  "fullName": "string",
  "mobile": "string",
  "password": "string",
  "confirmPassword": "string",
  "nationalId": "string",
  "address": "string",
  "nationalIdFront": "string (image URL)",
  "nationalIdBack": "string (image URL)",
  "gender": "MALE|FEMALE"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "string",
    "fullName": "string",
    "mobile": "string",
    "role": "USER",
    "totalPoints": 0,
    "status": "PENDING"
  }
}
```

---

### Verify National ID
**POST** `/users/verify-id`

**Description:** Verify user's national ID

**Request Body:**
```json
{
  "nationalId": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "exists": false
  }
}
```

---

## 🏭 Recycling Unit Endpoints (Mobile)

### Register Recycling Unit
**POST** `/recycling-units/register`

**Description:** Register a new recycling unit

**Request Body:**
```json
{
  "unitName": "string",
  "phoneNumber": "string",
  "password": "string",
  "confirmPassword": "string",
  "unitOwnerName": "string",
  "unitType": "PRESS|SHREDDER|WASHING_LINE",
  "address": "string",
  "workersCount": 0,
  "machinesCount": 0,
  "stationCapacity": 0,
  "idCardFrontImage": "string (image URL)",
  "idCardBackImage": "string (image URL)",
  "rentalContractImage": "string (image URL, optional)",
  "commercialRegisterImage": "string (image URL, optional)",
  "taxCardImage": "string (image URL, optional)"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "string",
    "unitName": "string",
    "phoneNumber": "string",
    "unitOwnerName": "string",
    "unitType": "PRESS|SHREDDER|WASHING_LINE",
    "status": "PENDING"
  }
}
```

---

## 📦 Sender Endpoints (Mobile - PRESS Units Only)

**Authentication:** Required (Recycling Unit with PRESS type)

### Create Sender
**POST** `/senders`

**Description:** Create a new sender (auto-assigned to current unit)

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "fullName": "string",
  "nationalId": "string",
  "address": "string",
  "mobileNumber": "string",
  "nationalIdFront": "string (image URL)",
  "nationalIdBack": "string (image URL)",
  "gender": "MALE|FEMALE",
  "senderType": "RESIDENTIAL_UNIT|COLLECTION_CENTER|MOBILE_COLLECTION|COLLECTION_WORKER",
  "expectedDailyAmount": 0,
  "haveSmartPhone": true,
  "familyCompany": false
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "string",
    "fullName": "string",
    "nationalId": "string",
    "address": "string",
    "mobileNumber": "string",
    "gender": "MALE|FEMALE",
    "senderType": "RESIDENTIAL_UNIT|COLLECTION_CENTER|MOBILE_COLLECTION|COLLECTION_WORKER",
    "status": "PENDING",
    "assignedUnits": [
      {
        "id": "string",
        "unitName": "string"
      }
    ]
  }
}
```

---

### Update Sender
**PUT** `/senders/{id}`

**Description:** Update a sender

**Headers:** `Authorization: Bearer <token>`

**Request Body:** (Same as Create Sender, all fields optional)

**Response (200 OK):** Updated sender object

---

### Get Assigned Senders
**GET** `/senders/assigned`

**Description:** Get all senders assigned to current unit

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page` (number, default: 1)
- `pageSize` (number, default: 20, max: 100)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "string",
        "fullName": "string",
        "nationalId": "string",
        "mobileNumber": "string",
        "senderType": "string",
        "status": "string"
      }
    ],
    "total": 0,
    "page": 1,
    "pageSize": 20
  }
}
```

---

## 🚚 Raw Material Shipments (Mobile - PRESS Units Only)

**Authentication:** Required (Recycling Unit with PRESS type)

### Create Raw Material Shipment
**POST** `/raw-material-shipments-received`

**Description:** Create a new raw material shipment received

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "shipmentImage": "string (image URL)",
  "wasteTypeId": "string",
  "weight": 0.0,
  "senderId": "string",
  "shipmentNumber": "string (optional, auto-generated if not provided)",
  "receiptImage": "string (image URL, optional)"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "string",
    "shipmentNumber": "string",
    "shipmentImage": "string",
    "weight": 0.0,
    "status": "PENDING|APPROVED|REJECTED",
    "wasteType": {
      "id": "string",
      "nameAr": "string",
      "nameEn": "string"
    },
    "sender": {
      "id": "string",
      "fullName": "string",
      "mobileNumber": "string"
    },
    "recyclingUnit": {
      "id": "string",
      "unitName": "string"
    }
  },
  "message": "Raw material shipment received successfully"
}
```

---

### List Raw Material Shipments
**GET** `/raw-material-shipments-received`

**Description:** Get all raw material shipments for current unit

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page` (number, default: 1)
- `pageSize` (number, default: 20, max: 100)
- `senderId` (string, optional)
- `wasteTypeId` (string, optional)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [ /* array of shipment objects */ ],
    "total": 0,
    "page": 1,
    "pageSize": 20
  }
}
```

---

### Get Raw Material Shipment
**GET** `/raw-material-shipments-received/{id}`

**Description:** Get a specific shipment

**Headers:** `Authorization: Bearer <token>`

**Response (200 OK):** Shipment object

---

### Update Raw Material Shipment
**PUT** `/raw-material-shipments-received/{id}`

**Description:** Update a shipment

**Headers:** `Authorization: Bearer <token>`

**Request Body:** (Same as Create, all fields optional)

**Response (200 OK):** Updated shipment object

---

### Delete Raw Material Shipment
**DELETE** `/raw-material-shipments-received/{id}`

**Description:** Delete a shipment

**Headers:** `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Shipment deleted successfully"
}
```

---

## 📦 Processed Material Shipments (Mobile - PRESS Units Only)

**Authentication:** Required (Recycling Unit with PRESS type)

### Create Processed Material Shipment (Step 1)
**POST** `/processed-material-shipments-sent`

**Description:** Create a processed material shipment (Step 1 - From Press)

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "shipmentImage": "string (image URL)",
  "materialTypeId": "string",
  "weight": 0.0,
  "carId": "string",
  "carPlateNumber": "string",
  "driverFirstName": "string",
  "driverSecondName": "string",
  "driverThirdName": "string",
  "receiverId": "string (SHREDDER or WASHING_LINE unit ID)",
  "tradeId": "string",
  "sentPalletsNumber": 0,
  "shipmentNumber": "string (optional, auto-generated)",
  "dateOfSending": "string (ISO date)",
  "receiptFromPress": "string (image URL, optional)",
  "status": "SENT_TO_FACTORY|SENT_TO_ADMIN|PENDING"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "string",
    "shipmentNumber": "string",
    "shipmentImage": "string",
    "weight": 0.0,
    "status": "string",
    "pressUnit": {
      "id": "string",
      "unitName": "string"
    },
    "receiver": {
      "id": "string",
      "unitName": "string"
    },
    "materialType": {
      "id": "string",
      "nameAr": "string"
    },
    "car": {
      "id": "string",
      "carPlate": "string"
    },
    "trade": {
      "id": "string",
      "name": "string"
    }
  },
  "message": "Processed material shipment created successfully"
}
```

---

### List Processed Material Shipments
**GET** `/processed-material-shipments-sent`

**Description:** Get all processed material shipments for current unit

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page` (number, default: 1)
- `pageSize` (number, default: 20, max: 100)
- `materialTypeId` (string, optional)
- `status` (string, optional)
- `shipmentNumber` (string, optional)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [ /* array of shipment objects */ ],
    "total": 0,
    "page": 1,
    "pageSize": 20
  }
}
```

---

### Get Processed Material Shipment
**GET** `/processed-material-shipments-sent/{id}`

**Description:** Get a specific shipment

**Headers:** `Authorization: Bearer <token>`

**Response (200 OK):** Shipment object

---

### Receive Processed Material Shipment (Step 2)
**POST** `/processed-material-shipments-sent/{id}/receive`

**Description:** Complete Step 2 - receive shipment at factory

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "factoryUnitId": "string",
  "carCheckImage": "string (image URL, optional)",
  "receiptImage": "string (image URL, optional)",
  "receivedWeight": 0.0,
  "emptyCarWeight": 0.0,
  "plenty": 0.0,
  "plentyReason": "string",
  "netWeight": 0.0
}
```

**Response (200 OK):** Updated shipment object

---

### Get Pending Receipt Shipments
**GET** `/processed-material-shipments-sent/pending-receipt`

**Description:** Get shipments pending receipt (for factory units)

**Headers:** `Authorization: Bearer <token>`

**Response (200 OK):** Array of shipment objects

---

### Get Received Shipments
**GET** `/processed-material-shipments-sent/received`

**Description:** Get received shipments (for factory units)

**Headers:** `Authorization: Bearer <token>`

**Response (200 OK):** Array of shipment objects

---

## 🚗 Car Endpoints (Public)

### List Cars
**GET** `/cars`

**Query Parameters:**
- `page` (number, default: 1)
- `pageSize` (number, default: 20, max: 100)
- `carTypeId` (string, optional)
- `carBrandId` (string, optional)
- `recyclingUnitId` (string, optional)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "string",
        "carPlate": "string",
        "carImage": "string",
        "maximumCapacity": 0.0,
        "carType": {
          "id": "string",
          "nameAr": "string",
          "nameEn": "string"
        },
        "carBrand": {
          "id": "string",
          "nameAr": "string",
          "nameEn": "string"
        },
        "assignedUnits": [
          {
            "id": "string",
            "unitName": "string"
          }
        ]
      }
    ],
    "total": 0,
    "page": 1,
    "pageSize": 20
  }
}
```

---

### Register Car
**POST** `/cars/register`

**Description:** Register a new car

**Request Body:**
```json
{
  "carTypeId": "string",
  "carBrandId": "string",
  "carPlate": "string",
  "maximumCapacity": 0.0,
  "carImage": "string (image URL)",
  "licenceFrontImage": "string (image URL)",
  "licenceBackImage": "string (image URL)"
}
```

**Response (201 Created):** Car object

---

## 📋 Reference Data Endpoints (Public)

### List Car Types
**GET** `/car-types`

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "nameAr": "string",
      "nameEn": "string",
      "createdAt": "string (ISO date)"
    }
  ]
}
```

---

### List Car Brands
**GET** `/car-brands`

**Response (200 OK):** Array of car brand objects (same structure as car types)

---

### List Waste Types
**GET** `/waste-types`

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "nameAr": "string",
      "nameEn": "string"
    }
  ]
}
```

---

### List Trades
**GET** `/trades`

**Query Parameters:**
- `page` (number, default: 1)
- `pageSize` (number, default: 20, max: 100)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "string",
        "name": "string"
      }
    ],
    "total": 0,
    "page": 1,
    "pageSize": 20
  }
}
```

---

### List Products
**GET** `/products`

**Description:** Get all products available for redemption

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "name": "string",
      "pointValuePerUnit": 0
    }
  ]
}
```

---

## 🏪 Inquiry Endpoints (Mobile)

### Create Inquiry (Step 1)
**POST** `/inquiries/create-step1`

**Description:** Create inquiry step 1

**Request Body:**
```json
{
  "senderId": "string",
  "inquiryDate": "string (ISO date)",
  "location": {
    "latitude": 0.0,
    "longitude": 0.0
  },
  "photos": ["string (image URL)"]
}
```

**Response (201 Created):** Inquiry object

---

### Create Inquiry (Step 2)
**POST** `/inquiries/create-step2`

**Description:** Complete inquiry step 2

**Request Body:**
```json
{
  "inquiryId": "string",
  "wasteTypeId": "string",
  "estimatedWeight": 0.0,
  "notes": "string (optional)"
}
```

**Response (200 OK):** Updated inquiry object

---

### List Inquiries
**GET** `/inquiries/list`

**Query Parameters:**
- `page` (number, default: 1)
- `pageSize` (number, default: 20)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [ /* inquiry objects */ ],
    "total": 0,
    "page": 1,
    "pageSize": 20
  }
}
```

---

### Approve Inquiry
**POST** `/inquiries/approve`

**Request Body:**
```json
{
  "inquiryId": "string"
}
```

**Response (200 OK):** Updated inquiry object

---

### Reject Inquiry
**POST** `/inquiries/reject`

**Request Body:**
```json
{
  "inquiryId": "string",
  "reason": "string (optional)"
}
```

**Response (200 OK):** Updated inquiry object

---

## 🎫 Registration Endpoints (Public)

### Create Registration
**POST** `/registration/create`

**Description:** Create registration request

**Request Body:** (Same as Register User or Register Recycling Unit)

**Response (201 Created):** Registration object with status "PENDING"

---

### Approve Registration
**POST** `/registration/approve`

**Description:** Approve registration (Admin only)

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "registrationId": "string"
}
```

---

### Reject Registration
**POST** `/registration/reject`

**Description:** Reject registration (Admin only)

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "registrationId": "string",
  "reason": "string (optional)"
}
```

---

## 👨‍💼 Admin Endpoints

**All admin endpoints require:** `Authorization: Bearer <admin_token>`

### Users Management

#### List Users
**GET** `/admin/users`
- Query: `page`, `pageSize`, `role`, `status`

#### Create User
**POST** `/admin/users`
```json
{
  "fullName": "string",
  "mobile": "string",
  "password": "string",
  "role": "USER|ADMIN",
  "nationalId": "string",
  "address": "string",
  "nationalIdFront": "string",
  "nationalIdBack": "string",
  "gender": "MALE|FEMALE"
}
```

#### Update User
**PUT** `/admin/users`
```json
{
  "id": "string",
  "fullName": "string (optional)",
  "mobile": "string (optional)",
  "password": "string (optional)",
  "role": "USER|ADMIN (optional)",
  "status": "PENDING|APPROVED|REJECTED (optional)"
}
```

#### Delete User
**DELETE** `/admin/users`
```json
{
  "id": "string"
}
```

---

### Recycling Units Management

#### List Recycling Units
**GET** `/admin/recycling-units`
- Query: `page`, `pageSize`, `unitType`, `status`

#### Create Recycling Unit
**POST** `/admin/recycling-units`
- Same structure as mobile registration

#### Update Recycling Unit
**PUT** `/admin/recycling-units/{id}`
- All fields optional

#### Delete Recycling Unit
**DELETE** `/admin/recycling-units/{id}`

#### Approve Recycling Unit
**PATCH** `/admin/recycling-units/{id}/approve`

#### Reject Recycling Unit
**PATCH** `/admin/recycling-units/{id}/reject`
```json
{
  "reason": "string (optional)"
}
```

---

### Raw Material Shipments (Admin)

#### Create Raw Material Shipment
**POST** `/admin/raw-material-shipments-received`
```json
{
  "shipmentImage": "string",
  "wasteTypeId": "string",
  "weight": 0.0,
  "senderId": "string",
  "recyclingUnitId": "string",
  "shipmentNumber": "string (optional)",
  "receiptImage": "string (optional)"
}
```

#### List Raw Material Shipments
**GET** `/admin/raw-material-shipments-received`
- Query: `page`, `pageSize`, `recyclingUnitId`, `senderId`, `wasteTypeId`, `status`

#### Get Raw Material Shipment
**GET** `/admin/raw-material-shipments-received/{id}`

#### Update Raw Material Shipment
**PUT** `/admin/raw-material-shipments-received/{id}`

#### Delete Raw Material Shipment
**DELETE** `/admin/raw-material-shipments-received/{id}`

#### Approve Raw Material Shipment
**PATCH** `/admin/raw-material-shipments-received/{id}/approve`

#### Reject Raw Material Shipment
**PATCH** `/admin/raw-material-shipments-received/{id}/reject`
```json
{
  "reason": "string (optional)"
}
```

---

### Processed Material Shipments (Admin)

#### Create Processed Material Shipment
**POST** `/admin/processed-material-shipments-sent`
- Same as mobile endpoint, but can specify `pressUnitId`

#### List Processed Material Shipments
**GET** `/admin/processed-material-shipments-sent`
- Query: `page`, `pageSize`, `pressUnitId`, `receiverId`, `factoryUnitId`, `materialTypeId`, `status`

#### Get Processed Material Shipment
**GET** `/admin/processed-material-shipments-sent/{id}`

#### Update Processed Material Shipment
**PUT** `/admin/processed-material-shipments-sent/{id}`

#### Delete Processed Material Shipment
**DELETE** `/admin/processed-material-shipments-sent/{id}`

#### Approve Processed Material Shipment
**PATCH** `/admin/processed-material-shipments-sent/{id}/approve`

#### Reject Processed Material Shipment
**PATCH** `/admin/processed-material-shipments-sent/{id}/reject`
```json
{
  "reason": "string (optional)"
}
```

#### Get Next Shipment Number
**GET** `/admin/processed-material-shipments-sent/next-number`

**Response:**
```json
{
  "success": true,
  "data": "PMS-0001"
}
```

---

### Senders Management (Admin)

#### List Senders
**GET** `/admin/senders`
- Query: `page`, `pageSize`, `recyclingUnitId`, `senderType`, `status`

#### Create Sender
**POST** `/admin/senders`
- Same as mobile endpoint

#### Get Sender
**GET** `/admin/senders/{id}`

#### Update Sender
**PUT** `/admin/senders/{id}`

#### Delete Sender
**DELETE** `/admin/senders/{id}`

#### Assign Sender to Units
**PUT** `/admin/senders/{id}/assign`
```json
{
  "recyclingUnitIds": ["string", "string"]
}
```

#### Get Senders by Units
**GET** `/admin/senders/by-units`
- Query: `unitIds` (comma-separated unit IDs)

---

### Cars Management (Admin)

#### List Cars
**GET** `/admin/cars`
- Query: `page`, `pageSize`, `carTypeId`, `carBrandId`, `recyclingUnitId`

#### Register Car
**POST** `/admin/cars/register`
- Same as public endpoint

#### Update Car
**PUT** `/admin/cars/{id}`

#### Delete Car
**DELETE** `/admin/cars/{id}`

---

### Reference Data Management (Admin)

#### Car Types
- **GET** `/admin/car-types` - List
- **POST** `/admin/car-types` - Create
- **PUT** `/admin/car-types` - Update
- **DELETE** `/admin/car-types` - Delete

#### Car Brands
- **GET** `/admin/car-brands` - List
- **POST** `/admin/car-brands` - Create
- **PUT** `/admin/car-brands` - Update
- **DELETE** `/admin/car-brands` - Delete

#### Waste Types
- **GET** `/admin/waste-types` - List
- **POST** `/admin/waste-types` - Create
- **PUT** `/admin/waste-types/{id}` - Update
- **DELETE** `/admin/waste-types/{id}` - Delete

#### Trades
- **GET** `/admin/trades` - List
- **POST** `/admin/trades` - Create
- **PUT** `/admin/trades/{id}` - Update
- **DELETE** `/admin/trades/{id}` - Delete

#### Products
- **GET** `/admin/products` - List
- **POST** `/admin/products` - Create
  ```json
  {
    "name": "string",
    "pointValuePerUnit": 0
  }
  ```
- **PUT** `/admin/products` - Update
- **DELETE** `/admin/products` - Delete

---

### Inquiries Management (Admin)

#### List Inquiries
**GET** `/admin/inquiries`
- Query: `page`, `pageSize`, `status`, `senderId`

---

### Assignments Management (Admin)

#### List Assignments
**GET** `/admin/assignments`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "sender": {
        "id": "string",
        "fullName": "string"
      },
      "recyclingUnit": {
        "id": "string",
        "unitName": "string"
      },
      "assignedAt": "string (ISO date)"
    }
  ]
}
```

#### Create Assignment
**POST** `/admin/assignments`
```json
{
  "senderId": "string",
  "recyclingUnitId": "string"
}
```

#### Delete Assignment
**DELETE** `/admin/assignments`
```json
{
  "id": "string"
}
```

---

### Stores Management (Admin)

#### List Stores
**GET** `/admin/stores`

#### Create Store
**POST** `/admin/stores`

#### Update Store
**PUT** `/admin/stores`

#### Delete Store
**DELETE** `/admin/stores`

---

### Activity Types Management (Admin)

#### List Activity Types
**GET** `/admin/activity-types`

#### Create Activity Type
**POST** `/admin/activity-types`

#### Update Activity Type
**PUT** `/admin/activity-types`

#### Delete Activity Type
**DELETE** `/admin/activity-types`

---

## 📝 Common Status Values

### User Status
- `PENDING` - Waiting for approval
- `APPROVED` - Approved and active
- `REJECTED` - Rejected

### Recycling Unit Status
- `PENDING` - Waiting for approval
- `APPROVED` - Approved and active
- `REJECTED` - Rejected

### Shipment Status
- `PENDING` - Waiting for approval
- `APPROVED` - Approved
- `REJECTED` - Rejected
- `SENT_TO_FACTORY` - Sent to factory
- `RECEIVED_AT_FACTORY` - Received at factory
- `SENT_TO_ADMIN` - Sent to admin

### Unit Types
- `PRESS` - Press unit
- `SHREDDER` - Shredder unit
- `WASHING_LINE` - Washing line unit

### Sender Types
- `RESIDENTIAL_UNIT` - Residential unit
- `COLLECTION_CENTER` - Collection center
- `MOBILE_COLLECTION` - Mobile collection
- `COLLECTION_WORKER` - Collection worker

### Genders
- `MALE`
- `FEMALE`

---

## 🔒 Error Codes

- `UNAUTHORIZED` (401) - Authentication required
- `FORBIDDEN` (403) - Insufficient permissions
- `VALIDATION_ERROR` (400) - Invalid request data
- `INTERNAL_ERROR` (500) - Server error
- `INVALID_CREDENTIALS` (401) - Invalid login credentials
- `NOT_FOUND` (404) - Resource not found

---

## 📌 Important Notes for Flutter Development

1. **Token Storage**: Store the `accessToken` securely (use `flutter_secure_storage` or similar)

2. **Image URLs**: Image URLs returned from upload endpoint are relative. Prepend your base URL:
   ```
   final imageUrl = baseUrl + data['url']; // e.g., "https://api.example.com/uploads/image.jpg"
   ```

3. **Pagination**: All list endpoints support pagination. Always check `total` to determine if more pages are available.

4. **CORS**: The API supports CORS. For mobile apps, this is not an issue, but be aware.

5. **Date Format**: Use ISO 8601 format for dates: `"2024-01-15T10:30:00.000Z"`

6. **Error Handling**: Always check `success` field in response before accessing `data`.

7. **File Upload**: Use `multipart/form-data` for image uploads. Consider using `http` or `dio` package with proper file handling.

---

## 📋 Business Workflow Documentation

### Processed Material Shipment Workflow: Press Unit → Factory → Admin

This section documents the complete business workflow for processed material shipments, from creation at the Press Unit through receipt at the Factory, to final approval/rejection by Admin.

---

### 🏭 Overview

The processed material shipment workflow is a **3-step process** that tracks processed materials (e.g., pressed plastic) from a PRESS unit to a factory unit (WASHING_LINE or SHREDDER), and finally to admin approval.

**Flow Diagram:**
```
PRESS Unit (Step 1) → Factory Unit (Step 2) → Admin (Step 3)
     ↓                        ↓                      ↓
SENT_TO_FACTORY      RECEIVED_AT_FACTORY       APPROVED/REJECTED
                     → SENT_TO_ADMIN
```

---

### 📊 Status Flow

The shipment progresses through the following statuses:

1. **SENT_TO_FACTORY** - Initial status when Press Unit creates shipment (Step 1)
2. **RECEIVED_AT_FACTORY** - (Optional intermediate status, currently not used)
3. **SENT_TO_ADMIN** - Status after Factory Unit completes Step 2 (receipt)
4. **APPROVED** - Final status when Admin approves the shipment
5. **REJECTED** - Final status when Admin rejects the shipment
6. **PENDING** - Alternative initial status (can be set by admin when creating shipment)

**Status Transition Rules:**
- `SENT_TO_FACTORY` → `SENT_TO_ADMIN` (via factory receipt)
- `SENT_TO_ADMIN` → `APPROVED` (via admin approve)
- `SENT_TO_ADMIN` → `REJECTED` (via admin reject)
- Once `APPROVED` or `REJECTED`, status cannot be changed

---

### 🔵 Step 1: Press Unit Creates Shipment

**Who:** PRESS unit (recycling unit with `unitType: "PRESS"`)  
**Endpoint:** `POST /api/processed-material-shipments-sent`  
**Status After:** `SENT_TO_FACTORY`

#### Business Rules:
1. Only PRESS units can create processed material shipments
2. The receiver must be a WASHING_LINE or SHREDDER unit
3. The car must be assigned to the press unit
4. All Step 1 fields are required (see API endpoint documentation)

#### Required Data (Step 1):
- **Shipment Information:**
  - `shipmentImage` - Photo of the shipment
  - `materialTypeId` - Type of processed material (waste type)
  - `weight` - Weight in tons
  - `sentPalletsNumber` - Number of pallets sent
  - `shipmentNumber` - Auto-generated if not provided (format: PMS-XXXX)
  - `dateOfSending` - Date when shipment was sent
  - `receiptFromPress` - Optional receipt image

- **Transportation Details:**
  - `carId` - Car used for transport (must be assigned to press unit)
  - `carPlateNumber` - Car plate number
  - `driverFirstName`, `driverSecondName`, `driverThirdName` - Driver's full name

- **Destination:**
  - `receiverId` - ID of WASHING_LINE or SHREDDER unit receiving the shipment
  - `tradeId` - Trader ID

#### What Happens:
1. System validates that the unit is a PRESS unit
2. System validates receiver is WASHING_LINE or SHREDDER
3. System validates car is assigned to press unit
4. System creates shipment with status `SENT_TO_FACTORY`
5. Shipment is now visible to the receiving factory unit

#### Mobile App Implementation:
```dart
// Step 1: Create shipment
final response = await http.post(
  Uri.parse('$baseUrl/api/processed-material-shipments-sent'),
  headers: {
    'Authorization': 'Bearer $pressUnitToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'shipmentImage': uploadedImageUrl,
    'materialTypeId': selectedMaterialTypeId,
    'weight': weightValue,
    'carId': selectedCarId,
    'carPlateNumber': carPlateNumber,
    'driverFirstName': driverFirstName,
    'driverSecondName': driverSecondName,
    'driverThirdName': driverThirdName,
    'receiverId': receiverUnitId, // WASHING_LINE or SHREDDER
    'tradeId': tradeId,
    'sentPalletsNumber': palletsNumber,
    'dateOfSending': dateOfSending.toIso8601String(),
    'receiptFromPress': receiptImageUrl, // optional
  }),
);
```

---

### 🏭 Step 2: Factory Unit Receives Shipment

**Who:** Factory unit (WASHING_LINE or SHREDDER)  
**Endpoint:** `POST /api/processed-material-shipments-sent/{id}/receive`  
**Status Before:** `SENT_TO_FACTORY`  
**Status After:** `SENT_TO_ADMIN`

#### Business Rules:
1. Only WASHING_LINE or SHREDDER units can receive shipments
2. Shipment must be in `SENT_TO_FACTORY` status
3. The factory unit receiving must match the `receiverId` from Step 1
4. System automatically calculates `netWeight` based on:
   - `receivedWeight` - Weight of car + shipment
   - `emptyCarWeight` - Weight of empty car
   - `plenty` - Percentage deduction (0-100%)
   - **Formula:** `netWeight = (receivedWeight - emptyCarWeight) × (1 - plenty/100)`

#### Required Data (Step 2):
- `factoryUnitId` - ID of factory unit (must match receiverId from Step 1)
- `carCheckImage` - Photo of car check at factory
- `receiptImage` - Receipt image
- `receivedWeight` - Total weight (car + shipment) in tons
- `emptyCarWeight` - Empty car weight in tons
- `plenty` - Deduction percentage (0-100)
- `plentyReason` - Reason for deduction (default: "هالك" / waste)

#### What Happens:
1. System validates shipment status is `SENT_TO_FACTORY`
2. System validates factory unit is WASHING_LINE or SHREDDER
3. System validates factory unit matches shipment receiver
4. System calculates `netWeight` automatically
5. System updates shipment with Step 2 data
6. System changes status to `SENT_TO_ADMIN`
7. Shipment is now visible to Admin for approval

#### Mobile App Implementation:
```dart
// Step 2: Receive shipment at factory
final response = await http.post(
  Uri.parse('$baseUrl/api/processed-material-shipments-sent/$shipmentId/receive'),
  headers: {
    'Authorization': 'Bearer $factoryUnitToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'factoryUnitId': factoryUnitId, // Must match receiverId
    'carCheckImage': carCheckImageUrl,
    'receiptImage': receiptImageUrl,
    'receivedWeight': receivedWeightValue,
    'emptyCarWeight': emptyCarWeightValue,
    'plenty': plentyPercentage, // e.g., 2.5 for 2.5%
    'plentyReason': 'هالك', // or custom reason
  }),
);

// System automatically calculates:
// netWeight = (receivedWeight - emptyCarWeight) * (1 - plenty / 100)
```

#### Viewing Pending Receipts (Factory):
Factory units can view shipments waiting to be received:
```dart
// Get pending shipments
GET /api/processed-material-shipments-sent/pending-receipt
```

---

### 👨‍💼 Step 3: Admin Approves/Rejects Shipment

**Who:** Admin user  
**Endpoints:**
- `PATCH /api/admin/processed-material-shipments-sent/{id}/approve` - Approve
- `PATCH /api/admin/processed-material-shipments-sent/{id}/reject` - Reject

**Status Before:** `SENT_TO_ADMIN`  
**Status After:** `APPROVED` or `REJECTED`

#### Business Rules:
1. Only Admin users can approve/reject
2. Shipment must be in `SENT_TO_ADMIN` status
3. Once approved or rejected, status cannot be changed
4. Rejection can include an optional reason

#### Approve Shipment:
- Changes status to `APPROVED`
- Records `approvedBy` (admin user ID)
- Shipment is considered complete

#### Reject Shipment:
- Changes status to `REJECTED`
- Records `rejectedBy` (admin user ID)
- Optionally records `rejectionReason`

#### What Happens:
1. Admin reviews shipment data (both Step 1 and Step 2 information)
2. Admin approves or rejects the shipment
3. System updates status and records who approved/rejected
4. Shipment workflow is complete

#### Admin Implementation:
```dart
// Approve shipment
final approveResponse = await http.patch(
  Uri.parse('$baseUrl/api/admin/processed-material-shipments-sent/$shipmentId/approve'),
  headers: {
    'Authorization': 'Bearer $adminToken',
    'Content-Type': 'application/json',
  },
);

// Reject shipment
final rejectResponse = await http.patch(
  Uri.parse('$baseUrl/api/admin/processed-material-shipments-sent/$shipmentId/reject'),
  headers: {
    'Authorization': 'Bearer $adminToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'reason': 'Optional rejection reason',
  }),
);
```

---

### 📈 Complete Workflow Example

#### Timeline:

**Day 1, 10:00 AM - Press Unit:**
1. Press unit creates shipment with Step 1 data
2. Status: `SENT_TO_FACTORY`
3. Shipment appears in factory unit's "pending receipts" list

**Day 1, 2:00 PM - Factory Unit:**
1. Factory unit receives the physical shipment
2. Factory unit weighs car + shipment
3. Factory unit weighs empty car
4. Factory unit calculates plenty percentage
5. Factory unit completes Step 2 via API
6. Status: `SENT_TO_ADMIN`
7. Shipment appears in admin's approval queue

**Day 1, 4:00 PM - Admin:**
1. Admin reviews shipment details
2. Admin verifies weights and calculations
3. Admin approves shipment
4. Status: `APPROVED`
5. Workflow complete

---

### 🔍 Viewing Shipments

#### For Press Units:
```dart
// List all shipments created by press unit
GET /api/processed-material-shipments-sent?page=1&pageSize=20

// Query parameters:
// - materialTypeId (optional)
// - status (optional)
// - shipmentNumber (optional)
```

#### For Factory Units:
```dart
// List pending receipts (status = SENT_TO_FACTORY)
GET /api/processed-material-shipments-sent/pending-receipt

// List received shipments (status = SENT_TO_ADMIN or later)
GET /api/processed-material-shipments-sent/received

// Get specific shipment
GET /api/processed-material-shipments-sent/{id}
```

#### For Admin:
```dart
// List all shipments with filters
GET /api/admin/processed-material-shipments-sent?page=1&pageSize=20

// Query parameters:
// - pressUnitId (optional)
// - receiverId (optional)
// - factoryUnitId (optional)
// - materialTypeId (optional)
// - status (optional)
// - shipmentNumber (optional)
```

---

### ⚠️ Important Business Validations

#### Validation Rules:

1. **Unit Type Restrictions:**
   - Only PRESS units can create shipments (Step 1)
   - Only WASHING_LINE or SHREDDER units can receive shipments (Step 2)
   - Receiver must match factory unit receiving

2. **Car Validation:**
   - Car must exist and be assigned to the press unit
   - Car plate number must be provided

3. **Status Transitions:**
   - Can only receive shipments in `SENT_TO_FACTORY` status
   - Can only approve/reject shipments in `SENT_TO_ADMIN` status
   - Cannot change status after `APPROVED` or `REJECTED`

4. **Weight Calculations:**
   - `receivedWeight` must be greater than `emptyCarWeight`
   - `plenty` must be between 0 and 100
   - `netWeight` is calculated automatically

5. **Required Relationships:**
   - Material type must exist
   - Trade must exist
   - Receiver unit must exist and be correct type
   - Factory unit must match receiver unit

---

### 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     STEP 1: PRESS UNIT                      │
├─────────────────────────────────────────────────────────────┤
│ Input:                                                       │
│ - Shipment image                                            │
│ - Material type, weight, pallets                            │
│ - Car details, driver info                                  │
│ - Receiver unit (WASHING_LINE/SHREDDER)                     │
│ - Trade, date                                               │
│                                                              │
│ Output:                                                      │
│ - Shipment created                                          │
│ - Status: SENT_TO_FACTORY                                   │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                  STEP 2: FACTORY UNIT                       │
├─────────────────────────────────────────────────────────────┤
│ Input:                                                       │
│ - Car check image                                           │
│ - Receipt image                                             │
│ - Received weight (car + shipment)                          │
│ - Empty car weight                                          │
│ - Plenty percentage & reason                                │
│                                                              │
│ Processing:                                                  │
│ - Calculate netWeight =                                     │
│   (receivedWeight - emptyCarWeight) × (1 - plenty/100)      │
│                                                              │
│ Output:                                                      │
│ - Shipment updated with Step 2 data                         │
│ - Status: SENT_TO_ADMIN                                     │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                      STEP 3: ADMIN                          │
├─────────────────────────────────────────────────────────────┤
│ Review:                                                      │
│ - All Step 1 data                                           │
│ - All Step 2 data                                           │
│ - Calculated netWeight                                      │
│                                                              │
│ Decision:                                                    │
│ - APPROVE → Status: APPROVED                                │
│   Record: approvedBy                                        │
│                                                              │
│ - REJECT → Status: REJECTED                                 │
│   Record: rejectedBy, rejectionReason                       │
└─────────────────────────────────────────────────────────────┘
```

---

### 💡 Business Logic Notes

1. **Net Weight Calculation:**
   - Formula: `netWeight = (receivedWeight - emptyCarWeight) × (1 - plenty/100)`
   - Example:
     - Received weight: 10.5 tons
     - Empty car weight: 2.0 tons
     - Plenty: 2.5%
     - Net weight = (10.5 - 2.0) × (1 - 2.5/100) = 8.5 × 0.975 = 8.2875 tons

2. **Plenty (الفضلات/Waste):**
   - Represents the percentage of material that is not usable
   - Typically includes moisture, contamination, or processing waste
   - Default reason is "هالك" (waste/damaged)
   - Used to calculate the actual usable net weight

3. **Shipment Number:**
   - Auto-generated format: `PMS-XXXX` (Processed Material Shipment)
   - Can be manually provided if needed
   - Must be unique

4. **Image Requirements:**
   - Step 1: `shipmentImage` (required), `receiptFromPress` (optional)
   - Step 2: `carCheckImage` (required), `receiptImage` (required)
   - All images must be uploaded via `/api/upload/image` first

5. **Admin Override:**
   - Admin can create shipments directly with all data
   - Admin can set initial status to `PENDING` or `SENT_TO_ADMIN`
   - Admin can update any field before approval

---

### 🔄 Alternative Workflows

#### Admin Creates Shipment Directly:
- Admin can create shipment with both Step 1 and Step 2 data
- Can set status to `SENT_TO_ADMIN` immediately
- Then approves/rejects directly

#### Shipment Created but Not Received:
- If factory unit doesn't receive, shipment stays in `SENT_TO_FACTORY`
- Can be viewed in factory unit's "pending receipts"
- Can be cancelled by admin if needed

#### Rejected Shipments:
- Once rejected, status cannot be changed
- Rejection reason is stored for audit
- Rejected shipments appear in admin list with status `REJECTED`

---

### 📝 Complete Data Model

#### Step 1 Fields (From Press):
- `shipmentImage` - Image URL
- `materialTypeId` - Reference to WasteType
- `weight` - Initial weight estimate (tons)
- `carId` - Reference to Car
- `carPlateNumber` - String
- `driverFirstName`, `driverSecondName`, `driverThirdName` - Driver name parts
- `receiverId` - Reference to RecyclingUnit (WASHING_LINE/SHREDDER)
- `tradeId` - Reference to Trade
- `sentPalletsNumber` - Integer
- `shipmentNumber` - String (auto-generated)
- `dateOfSending` - DateTime
- `receiptFromPress` - Image URL (optional)
- `pressUnitId` - Reference to RecyclingUnit (PRESS) - auto-set from auth

#### Step 2 Fields (From Factory):
- `carCheckImage` - Image URL
- `receiptImage` - Image URL
- `receivedWeight` - Actual received weight (tons)
- `emptyCarWeight` - Empty car weight (tons)
- `plenty` - Percentage (0-100)
- `plentyReason` - String (default: "هالك")
- `netWeight` - Calculated (automatically set)
- `factoryUnitId` - Reference to RecyclingUnit - auto-set from auth

#### Status & Audit Fields:
- `status` - Enum: SENT_TO_FACTORY | RECEIVED_AT_FACTORY | SENT_TO_ADMIN | PENDING | APPROVED | REJECTED
- `rejectionReason` - String (if rejected)
- `createdBy` - Admin user ID (if created by admin)
- `approvedBy` - Admin user ID (if approved)
- `rejectedBy` - Admin user ID (if rejected)
- `createdAt` - DateTime
- `updatedAt` - DateTime

---

### 🎯 Best Practices for Mobile App

1. **Step 1 Implementation:**
   - Upload images before creating shipment
   - Validate all required fields before submission
   - Show loading state during creation
   - Display success message with shipment number
   - Allow viewing created shipments

2. **Step 2 Implementation:**
   - Show pending receipts list with filter
   - Implement weight input with decimal support
   - Calculate and display net weight preview
   - Validate received weight > empty car weight
   - Show confirmation before submission

3. **Admin Implementation:**
   - Show all shipments with filters
   - Display complete data (both steps)
   - Highlight calculated net weight
   - Require confirmation for approve/reject
   - Show rejection reason input field

4. **Error Handling:**
   - Handle validation errors gracefully
   - Show user-friendly error messages
   - Retry failed requests
   - Validate status before operations

---

## 📚 Example Flutter Code Snippets

### Login Example
```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'mobile': mobileController.text,
    'password': passwordController.text,
  }),
);

final data = jsonDecode(response.body);
if (data['success']) {
  final token = data['data']['accessToken'];
  // Store token securely
  await storage.write(key: 'accessToken', value: token);
}
```

### Authenticated Request Example
```dart
final token = await storage.read(key: 'accessToken');
final response = await http.get(
  Uri.parse('$baseUrl/api/raw-material-shipments-received?page=1&pageSize=20'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
```

### Image Upload Example
```dart
final request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/api/upload/image'),
);

request.files.add(
  await http.MultipartFile.fromPath('file', imagePath),
);

final response = await request.send();
final responseData = await response.stream.bytesToString();
final data = jsonDecode(responseData);

if (data['success']) {
  final imageUrl = baseUrl + data['data']['url'];
  // Use imageUrl in your requests
}
```

---

**Last Updated:** 2024
**API Version:** 1.0
