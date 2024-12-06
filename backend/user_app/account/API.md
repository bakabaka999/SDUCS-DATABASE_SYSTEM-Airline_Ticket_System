# user_app/account API介绍

## 一、 应用功能介绍

该模块是用户视图下的账户模块。

## 二、 接口列表

### 1. 用户登录接口

#### 接口地址：/user_app/account/login/

#### 请求功能：用户通过提供用户名和密码进行身份验证。

#### 请求方式：POST

#### 请求参数：

```json
{
  "username": "string",  // 用户名
  "email": "string",     // 邮箱地址
  "password": "string"   // 密码
}
```

#### 返回参数：

- 成功：
```json
{
  "message": "Login successful"
}
```

- 失败
```json
{
  "error": "Invalid credentials"
}
```

### 2. 用户注册接口

#### 接口地址：/user_app/account/register/

#### 请求功能：用户通过提供用户名、邮箱、密码进行注册。

#### 请求方式：POST

#### 请求参数：

```json
{
  "username": "string",  // 用户名
  "email": "string",     // 邮箱地址
  "password": "string"   // 密码
}
```

#### 返回参数：

- 成功：
```json
{
  "message": "User created successfully"
}
```

- 失败
```json
{
  "error": "Username already exists"
}
```

### 3. 个人信息获取接口
#### 接口地址：
- 获取用户信息: /user_app/account/profile/
- 更新用户信息: /user_app/account/profile/

#### 请求功能：
- GET 获取用户信息
- PUT 更新用户信息

#### 请求方式：
- GET
- PUT

#### 请求参数：
- GET 请求无需参数
- PUT 请求参数：(目前只支持手机号和邮箱更新)
```json
{
  "phone_number": "string",   // 手机号
  "email": "string"           // 新邮箱地址
}
```

#### 返回参数：
- GET 请求：
```json
{
  "id": "integer",            // 用户ID
  "username": "string",       // 用户名
  "email": "string",          // 邮箱地址
  "phone_number": "string",   // 手机号
  "accumulated_miles": "integer",  // 累计里程
  "ticket_count": "integer"   // 购票次数
}

```
- PUT 请求：

    - 成功：
    ```json
    {
      "id": "integer",
      "username": "string",
      "email": "string",
      "phone_number": "string",
      "accumulated_miles": "integer",
      "ticket_count": "integer"
    }

    ```
    - 失败：

    ```json
    {
      "error": "Invalid data"
    }
    ```
  
### 4. 乘机人信息管理接口

#### 接口地址：
- 添加乘机人信息: /user_app/account/passenger/
- 删除乘机人信息: /user_app/account/passenger/<int:pk>/
- 更新乘机人信息: /user_app/account/passenger/<int:pk>/

#### 请求功能：
- GET 获取所有乘机人信息
- POST 添加乘机人信息
- DELETE 删除乘机人信息
- PUT 更新乘机人信息

#### 请求方式：
- GET
- POST
- DELETE
- PUT

#### 请求参数： 
- GET 请求无需参数
- POST 请求参数：
```json
{
  "name": "string",           // 乘机人姓名
  "gender": "boolean",        // 性别 (true=男, false=女)
  "phone_number": "string",   // 手机号
  "email": "string",          // 邮箱地址
  "conditions": "string",     // 认证条件（如学生认证、教师认证等）
  "birth_date": "YYYY-MM-DD"  // 出生日期
}
```
- DELETE 请求无需参数，但需要再Url中指定要删除的乘机人ID
- PUT 请求参数：
```json
{
  "name": "string",           // 乘机人姓名
  "gender": "boolean",        // 性别
  "phone_number": "string",   // 手机号
  "email": "string",          // 邮箱地址
  "conditions": "string",     // 认证条件
  "birth_date": "YYYY-MM-DD"  // 出生日期
}
```

#### 返回参数：
- GET 请求：
```json
[
  {
    "person_id": "string",
    "name": "string",
    "gender": "boolean",
    "phone_number": "string",
    "email": "string",
    "person_type": "string",
    "birth_date": "string"
  },
  ...
]

```
- POST 请求：
- 成功：
```json
{
  "person_id": "integer",     // 乘机人ID
  "name": "string",
  "gender": "boolean",
  "phone_number": "string",
  "email": "string",
  "conditions": "string",
  "birth_date": "YYYY-MM-DD"
}
```

- 失败：
```json
{
  "error": "Invalid data or duplicate passenger"
}
```

- DELETE 请求：
- 成功：
```json
{
  "message": "Passenger deleted successfully"
}
```

- 失败：
```json
{
  "error": "Passenger not found or not associated with the user."
}
```

- PUT 请求：
- 成功：
```json
{
  "person_id": "integer",     // 乘机人ID
  "name": "string",
  "gender": "boolean",
  "phone_number": "string",
  "email": "string",
  "conditions": "string",
  "birth_date": "YYYY-MM-DD"
}
```

- 失败：
```json
{
  "error": "Invalid data or passenger not found"
}
```

### 5. 发票管理接口

#### 接口地址：
- 获取用户发票列表: /user_app/account/invoice/
- 添加发票信息: /user_app/account/invoice/
- 删除发票信息: /user_app/account/invoice/<int:pk>/
- 更新发票信息: /user_app/account/invoice/<int:pk>/

#### 请求功能：
- GET 获取用户发票列表
- POST 添加发票信息
- DELETE 删除发票信息
- PUT 更新发票信息

#### 请求方式：
- GET
- POST
- DELETE
- PUT

#### 请求参数： 
- GET 请求无需参数
- POST 请求参数：
```json
{
  "type": "string",            // 发票类型（如个人、公司）
  "name": "string",            // 发票名称
  "identification_number": "string",   // 识别号（如果类型为“公司”时必填）
  "company_address": "string", // 公司地址（如果类型为“公司”时必填）
  "phone_number": "string",    // 电话号码
  "bank_name": "string",       // 开户行名称
  "bank_account": "string"     // 开户行账号
}
```
- DELETE 请求无需参数，但需要再Url中指定要删除的发票ID
- PUT 请求参数：
```json
{
  "type": "string",
  "name": "string",
  "identification_number": "string",
  "company_address": "string",
  "phone_number": "string",
  "bank_name": "string",
  "bank_account": "string"
}
      
```

#### 返回参数：
- GET 请求：
```json
[
  {
    "type": "string",
    "name": "string",
    "identification_number": "string",
    "company_address": "string",
    "phone_number": "string",
    "bank_name": "string",
    "bank_account": "string"
  },
  ...
]

```

- POST 请求：
- 成功：
```json
{
  "type": "string",
  "name": "string",
  "identification_number": "string",
  "company_address": "string",
  "phone_number": "string",
  "bank_name": "string",
  "bank_account": "string"
}
```

- PUT 请求：
- 成功：
```json
{
  "type": "string",
  "name": "string",
  "identification_number": "string",
  "company_address": "string",
  "phone_number": "string",
  "bank_name": "string",
  "bank_account": "string"
}
```

- DELETE 请求：
- 成功：
```json
{
  "message": "Invoice deleted successfully"
}
```

- 失败：
```json
{
  "error": "Invoice not found or not associated with the user."
}
```

### 6. 资质认证管理接口

#### 接口地址：/api/qualification-certification/
#### 请求功能：修改用户资质认证
#### 请求方式：POST
#### 请求参数：
```json
{
  "certification_type": "string"  # 认证类型 ('student', 'teacher', 'adult', 'senior')
}
```
#### 返回参数：
- 成功：
```json
{
  "message": "Certification successful"
}
```
- 失败
```json
{
  "error": "Invalid certification type"
}
```

### 7. 退出登录接口

#### 接口地址：/user_app/account/logout/

#### 请求功能：用户退出登录。

#### 请求方式：POST  

#### 请求参数：无

#### 返回参数：

- 成功：
```json
{
  "message": "Logout successful"
}
```
- 失败
```json
{
  "error": "Logout failed"
}
```


