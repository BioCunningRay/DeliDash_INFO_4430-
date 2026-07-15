/*We used chatgpt for this dataset - https://chatgpt.com/g/g-p-68f468f2a9108191be8558f5841d5fb4-homework-graduation-station/c/6a57063b-de44-83e8-8155-3f73f131267a */

USE delidashDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
    DeliDash development seed data
    --------------------------------
    Creates:
      4 roles
      24 addresses
      20 images
      20 users
      6 drivers
      12 available shifts
      12 driver shifts
      6 restaurants
      30 menu items
      60 orders
      120 order-detail rows
      60 tracking records
      60 transactions

    All generated user emails end in @delidash.test.

    NOTE:
    The Menu table currently has no ItemName column, so the seed data places
    the menu item's name at the beginning of Description.
*/

BEGIN TRY
    BEGIN TRANSACTION;

    /* ============================================================
       CLEAN UP PREVIOUS DELIDASH TEST ORDERS AND BUSINESS RECORDS
       ============================================================ */

    DELETE OD
    FROM OrderDetails OD
    INNER JOIN Orders O ON O.OrderID = OD.OrderID
    INNER JOIN Users U ON U.UserID = O.CustomerID
    WHERE U.Email LIKE '%@delidash.test';

    DELETE OT
    FROM OrderTracking OT
    INNER JOIN Orders O ON O.OrderID = OT.OrderID
    INNER JOIN Users U ON U.UserID = O.CustomerID
    WHERE U.Email LIKE '%@delidash.test';

    DELETE T
    FROM Transactions T
    INNER JOIN Orders O ON O.OrderID = T.OrderID
    INNER JOIN Users U ON U.UserID = O.CustomerID
    WHERE U.Email LIKE '%@delidash.test';

    DELETE O
    FROM Orders O
    INNER JOIN Users U ON U.UserID = O.CustomerID
    WHERE U.Email LIKE '%@delidash.test';

    DELETE DS
    FROM DriverShifts DS
    INNER JOIN Drivers D ON D.DriverID = DS.DriverID
    INNER JOIN Users U ON U.UserID = D.UserID
    WHERE U.Email LIKE '%@delidash.test';

    DELETE D
    FROM Drivers D
    INNER JOIN Users U ON U.UserID = D.UserID
    WHERE U.Email LIKE '%@delidash.test';

    DELETE M
    FROM Menu M
    INNER JOIN Restaurants R ON R.RestaurantID = M.RestaurantID
    INNER JOIN Users U ON U.UserID = R.OwnerID
    WHERE U.Email LIKE '%@delidash.test';

    DELETE R
    FROM Restaurants R
    INNER JOIN Users U ON U.UserID = R.OwnerID
    WHERE U.Email LIKE '%@delidash.test';

    DELETE FROM Users
    WHERE Email LIKE '%@delidash.test';

    /* ============================================================
       ROLES
       ============================================================ */

    IF NOT EXISTS (SELECT 1 FROM Role WHERE RoleName = 'Customer')
        INSERT INTO Role (RoleName) VALUES ('Customer');

    IF NOT EXISTS (SELECT 1 FROM Role WHERE RoleName = 'Driver')
        INSERT INTO Role (RoleName) VALUES ('Driver');

    IF NOT EXISTS (SELECT 1 FROM Role WHERE RoleName = 'RestaurantOwner')
        INSERT INTO Role (RoleName) VALUES ('RestaurantOwner');

    IF NOT EXISTS (SELECT 1 FROM Role WHERE RoleName = 'Administrator')
        INSERT INTO Role (RoleName) VALUES ('Administrator');

    /* ============================================================
       ADDRESSES
       ============================================================ */

    DECLARE @AddressSeed TABLE (
        StreetAddress VARCHAR(100),
        City VARCHAR(50),
        State VARCHAR(20),
        Zip VARCHAR(10)
    );

    INSERT INTO @AddressSeed (StreetAddress, City, State, Zip)
    VALUES
        ('101 Summit Ridge Drive', 'Draper', 'UT', '84020'),
        ('245 Traverse Mountain Boulevard', 'Lehi', 'UT', '84043'),
        ('318 State Street', 'Sandy', 'UT', '84070'),
        ('442 Canyon View Road', 'Draper', 'UT', '84020'),
        ('519 Redwood Road', 'Riverton', 'UT', '84065'),
        ('627 Main Street', 'American Fork', 'UT', '84003'),
        ('735 Pioneer Crossing', 'Lehi', 'UT', '84043'),
        ('814 Fort Union Boulevard', 'Midvale', 'UT', '84047'),
        ('928 University Parkway', 'Orem', 'UT', '84058'),
        ('1034 Center Street', 'Provo', 'UT', '84601'),
        ('1148 Highland Drive', 'Salt Lake City', 'UT', '84106'),
        ('1262 South Temple', 'Salt Lake City', 'UT', '84102'),
        ('1376 Bengal Boulevard', 'Cottonwood Heights', 'UT', '84121'),
        ('1480 Park Avenue', 'Park City', 'UT', '84060'),
        ('1594 River Park Drive', 'South Jordan', 'UT', '84095'),
        ('1608 Thanksgiving Way', 'Lehi', 'UT', '84043'),
        ('1722 Corner Canyon Road', 'Draper', 'UT', '84020'),
        ('1836 Blue Vista Lane', 'Herriman', 'UT', '84096'),
        ('1950 Mountain View Corridor', 'West Jordan', 'UT', '84081'),
        ('2064 Millrock Drive', 'Holladay', 'UT', '84121'),
        ('2178 Freedom Boulevard', 'Provo', 'UT', '84604'),
        ('2292 Geneva Road', 'Orem', 'UT', '84057'),
        ('2306 Foothill Drive', 'Salt Lake City', 'UT', '84109'),
        ('2420 Marketplace Drive', 'Draper', 'UT', '84020');

    INSERT INTO Address (StreetAddress, City, State, Zip)
    SELECT S.StreetAddress, S.City, S.State, S.Zip
    FROM @AddressSeed S
    WHERE NOT EXISTS (
        SELECT 1
        FROM Address A
        WHERE A.StreetAddress = S.StreetAddress
          AND A.City = S.City
          AND A.State = S.State
          AND A.Zip = S.Zip
    );

    /* ============================================================
       USERS
       PasswordHash values below are fake development placeholders.
       Do not use plaintext or shared hashes in production.
       ============================================================ */

    DECLARE @CustomerRoleID INT =
        (SELECT TOP 1 RoleID FROM Role WHERE RoleName = 'Customer');
    DECLARE @DriverRoleID INT =
        (SELECT TOP 1 RoleID FROM Role WHERE RoleName = 'Driver');
    DECLARE @OwnerRoleID INT =
        (SELECT TOP 1 RoleID FROM Role WHERE RoleName = 'RestaurantOwner');
    DECLARE @AdminRoleID INT =
        (SELECT TOP 1 RoleID FROM Role WHERE RoleName = 'Administrator');

    INSERT INTO Users
        (FirstName, LastName, Email, PasswordHash, Phone, RoleID, AddressID, ProfilePic)
    VALUES
        ('Alex', 'Morgan', 'alex.morgan@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000001', '801-555-0101',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '101 Summit Ridge Drive'),
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%customer-alex.jpg')),

        ('Jamie', 'Chen', 'jamie.chen@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000002', '801-555-0102',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '245 Traverse Mountain Boulevard'),
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%customer-jamie.jpg')),

        ('Taylor', 'Brooks', 'taylor.brooks@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000003', '801-555-0103',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '318 State Street'),
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%customer-taylor.jpg')),

        ('Jordan', 'Lee', 'jordan.lee@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000004', '801-555-0104',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '442 Canyon View Road'), NULL),

        ('Casey', 'Reed', 'casey.reed@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000005', '801-555-0105',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '519 Redwood Road'), NULL),

        ('Riley', 'Patel', 'riley.patel@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000006', '801-555-0106',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '627 Main Street'), NULL),

        ('Morgan', 'Diaz', 'morgan.diaz@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000007', '801-555-0107',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '735 Pioneer Crossing'), NULL),

        ('Avery', 'Kim', 'avery.kim@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000008', '801-555-0108',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '814 Fort Union Boulevard'), NULL),

        ('Cameron', 'Price', 'cameron.price@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000009', '801-555-0109',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '928 University Parkway'), NULL),

        ('Quinn', 'Walker', 'quinn.walker@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000010', '801-555-0110',
            @CustomerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1034 Center Street'), NULL),

        ('Maya', 'Johnson', 'maya.johnson@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000011', '801-555-0201',
            @DriverRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1148 Highland Drive'),
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%driver-maya.jpg')),

        ('Ethan', 'Williams', 'ethan.williams@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000012', '801-555-0202',
            @DriverRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1262 South Temple'),
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%driver-ethan.jpg')),

        ('Sofia', 'Martinez', 'sofia.martinez@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000013', '801-555-0203',
            @DriverRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1376 Bengal Boulevard'),
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%driver-sofia.jpg')),

        ('Noah', 'Anderson', 'noah.anderson@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000014', '801-555-0204',
            @DriverRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1480 Park Avenue'), NULL),

        ('Olivia', 'Nguyen', 'olivia.nguyen@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000015', '801-555-0205',
            @DriverRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1594 River Park Drive'), NULL),

        ('Liam', 'Garcia', 'liam.garcia@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000016', '801-555-0206',
            @DriverRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1608 Thanksgiving Way'), NULL),

        ('Priya', 'Shah', 'priya.shah@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000017', '801-555-0301',
            @OwnerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1722 Corner Canyon Road'), NULL),

        ('Marco', 'Rossi', 'marco.rossi@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000018', '801-555-0302',
            @OwnerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1836 Blue Vista Lane'), NULL),

        ('Elena', 'Torres', 'elena.torres@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000019', '801-555-0303',
            @OwnerRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '1950 Mountain View Corridor'), NULL),

        ('Drew', 'Administrator', 'admin@delidash.test', '$2a$10$DEVONLYHASH000000000000000000000000000000000000020', '801-555-0401',
            @AdminRoleID,
            (SELECT AddressID FROM Address WHERE StreetAddress = '2064 Millrock Drive'), NULL);

    /* ============================================================
       DRIVERS
       ============================================================ */

    INSERT INTO Drivers (UserID, VehicleType, Rating, Availability)
    VALUES
        ((SELECT UserID FROM Users WHERE Email = 'maya.johnson@delidash.test'), 'Compact Car', 4.9, 'Available'),
        ((SELECT UserID FROM Users WHERE Email = 'ethan.williams@delidash.test'), 'SUV', 4.7, 'Delivering'),
        ((SELECT UserID FROM Users WHERE Email = 'sofia.martinez@delidash.test'), 'Hybrid Car', 4.8, 'Available'),
        ((SELECT UserID FROM Users WHERE Email = 'noah.anderson@delidash.test'), 'Motorcycle', 4.5, 'Offline'),
        ((SELECT UserID FROM Users WHERE Email = 'olivia.nguyen@delidash.test'), 'Electric Car', 4.9, 'Available'),
        ((SELECT UserID FROM Users WHERE Email = 'liam.garcia@delidash.test'), 'Bicycle', 4.6, 'Available');

    /* ============================================================
       AVAILABLE SHIFTS
       ============================================================ */

    DELETE FROM AvailableShifts
    WHERE ShiftStart >= '2026-07-15T00:00:00'
      AND ShiftStart <  '2026-07-19T00:00:00';

    INSERT INTO AvailableShifts (ShiftStart, ShiftEnd, Bonus)
    VALUES
        ('2026-07-15T08:00:00', '2026-07-15T12:00:00', '$5'),
        ('2026-07-15T11:00:00', '2026-07-15T15:00:00', '$8'),
        ('2026-07-15T17:00:00', '2026-07-15T22:00:00', '$12'),
        ('2026-07-16T08:00:00', '2026-07-16T12:00:00', NULL),
        ('2026-07-16T11:00:00', '2026-07-16T15:00:00', '$6'),
        ('2026-07-16T17:00:00', '2026-07-16T22:00:00', '$15'),
        ('2026-07-17T08:00:00', '2026-07-17T12:00:00', '$5'),
        ('2026-07-17T11:00:00', '2026-07-17T15:00:00', '$10'),
        ('2026-07-17T17:00:00', '2026-07-17T23:00:00', '$18'),
        ('2026-07-18T09:00:00', '2026-07-18T14:00:00', '$12'),
        ('2026-07-18T14:00:00', '2026-07-18T19:00:00', '$15'),
        ('2026-07-18T18:00:00', '2026-07-18T23:59:00', '$20');

    /* ============================================================
       DRIVER SHIFTS
       ============================================================ */

    INSERT INTO DriverShifts (DriverID, ShiftStart, ShiftEnd, Status)
    VALUES
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'maya.johnson@delidash.test'),
            '2026-07-12T08:00:00', '2026-07-12T12:00:00', 'Completed'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'maya.johnson@delidash.test'),
            '2026-07-15T17:00:00', '2026-07-15T22:00:00', 'Scheduled'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'ethan.williams@delidash.test'),
            '2026-07-13T11:00:00', '2026-07-13T15:00:00', 'Completed'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'ethan.williams@delidash.test'),
            '2026-07-16T17:00:00', '2026-07-16T22:00:00', 'Scheduled'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'sofia.martinez@delidash.test'),
            '2026-07-13T17:00:00', '2026-07-13T22:00:00', 'Completed'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'sofia.martinez@delidash.test'),
            '2026-07-17T11:00:00', '2026-07-17T15:00:00', 'Scheduled'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'noah.anderson@delidash.test'),
            '2026-07-11T18:00:00', '2026-07-11T22:00:00', 'Cancelled'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'noah.anderson@delidash.test'),
            '2026-07-18T14:00:00', '2026-07-18T19:00:00', 'Scheduled'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'olivia.nguyen@delidash.test'),
            '2026-07-14T08:00:00', '2026-07-14T12:00:00', 'Completed'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'olivia.nguyen@delidash.test'),
            '2026-07-18T18:00:00', '2026-07-18T23:59:00', 'Scheduled'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'liam.garcia@delidash.test'),
            '2026-07-14T11:00:00', '2026-07-14T15:00:00', 'Completed'),
        ((SELECT D.DriverID FROM Drivers D JOIN Users U ON U.UserID = D.UserID WHERE U.Email = 'liam.garcia@delidash.test'),
            '2026-07-17T08:00:00', '2026-07-17T12:00:00', 'Scheduled');

    /* ============================================================
       RESTAURANTS
       ============================================================ */

    INSERT INTO Restaurants (Name, OwnerID, AddressID, Rating)
    VALUES
        ('Wasatch Burger Co.',
            (SELECT UserID FROM Users WHERE Email = 'priya.shah@delidash.test'),
            (SELECT AddressID FROM Address WHERE StreetAddress = '2178 Freedom Boulevard'), 4.7),

        ('Little Italy Kitchen',
            (SELECT UserID FROM Users WHERE Email = 'marco.rossi@delidash.test'),
            (SELECT AddressID FROM Address WHERE StreetAddress = '2292 Geneva Road'), 4.8),

        ('Canyon Tacos',
            (SELECT UserID FROM Users WHERE Email = 'elena.torres@delidash.test'),
            (SELECT AddressID FROM Address WHERE StreetAddress = '2306 Foothill Drive'), 4.6),

        ('Curry Peak',
            (SELECT UserID FROM Users WHERE Email = 'priya.shah@delidash.test'),
            (SELECT AddressID FROM Address WHERE StreetAddress = '2420 Marketplace Drive'), 4.9),

        ('Sushi Summit',
            (SELECT UserID FROM Users WHERE Email = 'marco.rossi@delidash.test'),
            (SELECT AddressID FROM Address WHERE StreetAddress = '1594 River Park Drive'), 4.5),

        ('Fresh Fork Cafe',
            (SELECT UserID FROM Users WHERE Email = 'elena.torres@delidash.test'),
            (SELECT AddressID FROM Address WHERE StreetAddress = '1376 Bengal Boulevard'), 4.7);

    /* ============================================================
       MENU ITEMS: 5 PER RESTAURANT
       ============================================================ */

    INSERT INTO Menu (RestaurantID, Price, Description, ImageID)
    VALUES
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Wasatch Burger Co.'), 11.99,
            'Classic Wasatch Burger - Beef patty, cheddar, lettuce, tomato, onion, and house sauce.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%burger.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Wasatch Burger Co.'), 13.49,
            'Bacon Summit Burger - Beef patty, bacon, pepper jack, jalapenos, and smoky sauce.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%burger.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Wasatch Burger Co.'), 9.99,
            'Crispy Chicken Sandwich - Fried chicken, pickles, slaw, and spicy mayonnaise.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%sandwich.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Wasatch Burger Co.'), 4.49,
            'Mountain Fries - Seasoned fries served with fry sauce.',
            NULL),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Wasatch Burger Co.'), 6.49,
            'Chocolate Shake - Hand-spun chocolate milkshake.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%drink.jpg')),

        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Little Italy Kitchen'), 15.99,
            'Chicken Alfredo - Fettuccine, grilled chicken, parmesan, and creamy Alfredo sauce.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%pasta.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Little Italy Kitchen'), 14.49,
            'Spaghetti Bolognese - Slow-cooked beef sauce over spaghetti.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%pasta.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Little Italy Kitchen'), 16.99,
            'Pepperoni Pizza - Twelve-inch pizza with mozzarella and pepperoni.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%pizza.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Little Italy Kitchen'), 7.49,
            'Garlic Breadsticks - Six breadsticks with garlic butter and marinara.',
            NULL),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Little Italy Kitchen'), 7.99,
            'Tiramisu - Espresso-soaked layered Italian dessert.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%dessert.jpg')),

        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Canyon Tacos'), 10.99,
            'Carne Asada Tacos - Three tacos with steak, onion, cilantro, and salsa.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%tacos.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Canyon Tacos'), 9.99,
            'Chicken Street Tacos - Three tacos with marinated chicken and fresh toppings.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%tacos.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Canyon Tacos'), 12.49,
            'Canyon Burrito - Rice, beans, meat, cheese, salsa, and sour cream.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%burrito.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Canyon Tacos'), 8.49,
            'Loaded Nachos - Tortilla chips, queso, beans, pico, and jalapenos.',
            NULL),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Canyon Tacos'), 3.49,
            'Horchata - Sweet cinnamon rice drink served cold.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%drink.jpg')),

        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Curry Peak'), 15.49,
            'Chicken Tikka Masala - Roasted chicken in tomato cream sauce with basmati rice.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%curry.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Curry Peak'), 14.49,
            'Paneer Butter Masala - Paneer cheese in a rich tomato butter sauce.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%curry.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Curry Peak'), 13.99,
            'Chana Masala - Chickpeas cooked with tomato, onion, and warming spices.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%curry.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Curry Peak'), 4.49,
            'Garlic Naan - Tandoor-baked flatbread brushed with garlic butter.',
            NULL),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Curry Peak'), 5.99,
            'Mango Lassi - Chilled mango yogurt drink.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%drink.jpg')),

        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Sushi Summit'), 14.99,
            'Summit Roll - Salmon, avocado, cucumber, spicy mayonnaise, and sesame.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%sushi.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Sushi Summit'), 12.99,
            'California Roll Combo - Two California rolls with ginger and wasabi.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%sushi.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Sushi Summit'), 17.49,
            'Salmon Nigiri Plate - Eight pieces of fresh salmon nigiri.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%sushi.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Sushi Summit'), 6.49,
            'Vegetable Gyoza - Six pan-fried vegetable dumplings.',
            NULL),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Sushi Summit'), 4.99,
            'Miso Soup and Edamame - Traditional soup with a side of salted edamame.',
            NULL),

        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Fresh Fork Cafe'), 11.49,
            'Harvest Chicken Salad - Greens, chicken, apple, pecans, feta, and vinaigrette.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%salad.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Fresh Fork Cafe'), 10.49,
            'Mediterranean Bowl - Quinoa, chickpeas, cucumber, tomato, olives, and hummus.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%salad.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Fresh Fork Cafe'), 9.99,
            'Turkey Avocado Sandwich - Turkey, avocado, greens, tomato, and herb spread.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%sandwich.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Fresh Fork Cafe'), 8.99,
            'Sunrise Breakfast Plate - Eggs, breakfast potatoes, toast, and fruit.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%breakfast.jpg')),
        ((SELECT RestaurantID FROM Restaurants WHERE Name = 'Fresh Fork Cafe'), 5.49,
            'Berry Smoothie - Strawberry, blueberry, banana, yogurt, and honey.',
            (SELECT ImageID FROM Images WHERE CloudURL LIKE '%drink.jpg'));

    /* ============================================================
       GENERATE 60 ORDERS
       ============================================================ */

    DECLARE @Customers TABLE (
        RowNum INT IDENTITY(1,1),
        UserID INT
    );

    INSERT INTO @Customers (UserID)
    SELECT UserID
    FROM Users
    WHERE RoleID = @CustomerRoleID
      AND Email LIKE '%@delidash.test'
    ORDER BY UserID;

    DECLARE @Restaurants TABLE (
        RowNum INT IDENTITY(1,1),
        RestaurantID INT
    );

    INSERT INTO @Restaurants (RestaurantID)
    SELECT R.RestaurantID
    FROM Restaurants R
    INNER JOIN Users U ON U.UserID = R.OwnerID
    WHERE U.Email LIKE '%@delidash.test'
    ORDER BY R.RestaurantID;

    DECLARE @Drivers TABLE (
        RowNum INT IDENTITY(1,1),
        DriverID INT
    );

    INSERT INTO @Drivers (DriverID)
    SELECT D.DriverID
    FROM Drivers D
    INNER JOIN Users U ON U.UserID = D.UserID
    WHERE U.Email LIKE '%@delidash.test'
    ORDER BY D.DriverID;

    DECLARE @NewOrders TABLE (
        SequenceNumber INT,
        OrderID INT,
        RestaurantID INT
    );

    DECLARE @i INT = 1;
    DECLARE @CustomerCount INT = (SELECT COUNT(*) FROM @Customers);
    DECLARE @RestaurantCount INT = (SELECT COUNT(*) FROM @Restaurants);
    DECLARE @DriverCount INT = (SELECT COUNT(*) FROM @Drivers);

    WHILE @i <= 60
    BEGIN
        DECLARE @CustomerID INT =
            (SELECT UserID FROM @Customers
             WHERE RowNum = ((@i - 1) % @CustomerCount) + 1);

        DECLARE @RestaurantID INT =
            (SELECT RestaurantID FROM @Restaurants
             WHERE RowNum = (((@i * 3) - 1) % @RestaurantCount) + 1);

        DECLARE @DriverID INT =
            CASE
                WHEN @i % 10 = 0 THEN NULL
                ELSE (
                    SELECT DriverID FROM @Drivers
                    WHERE RowNum = (((@i * 2) - 1) % @DriverCount) + 1
                )
            END;

        DECLARE @Status VARCHAR(25) =
            CASE @i % 6
                WHEN 0 THEN 'Delivered'
                WHEN 1 THEN 'Placed'
                WHEN 2 THEN 'Confirmed'
                WHEN 3 THEN 'Preparing'
                WHEN 4 THEN 'Out for Delivery'
                ELSE 'Cancelled'
            END;

        DECLARE @OrderDate DATETIME =
            DATEADD(HOUR, -(@i * 7), CAST('2026-07-14T21:00:00' AS DATETIME));

        INSERT INTO Orders
            (CustomerID, RestaurantID, DriverID, OrderStatus, OrderTotal, OrderDate)
        VALUES
            (@CustomerID, @RestaurantID, @DriverID, @Status, 0.00, @OrderDate);

        INSERT INTO @NewOrders (SequenceNumber, OrderID, RestaurantID)
        VALUES (@i, SCOPE_IDENTITY(), @RestaurantID);

        SET @i += 1;
    END;

    /* ============================================================
       TWO ORDER DETAILS PER ORDER
       ============================================================ */

    DECLARE @OrderSequence INT;
    DECLARE @GeneratedOrderID INT;
    DECLARE @GeneratedRestaurantID INT;

    DECLARE OrderCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT SequenceNumber, OrderID, RestaurantID
        FROM @NewOrders
        ORDER BY SequenceNumber;

    OPEN OrderCursor;

    FETCH NEXT FROM OrderCursor
    INTO @OrderSequence, @GeneratedOrderID, @GeneratedRestaurantID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @RestaurantMenu TABLE (
            RowNum INT,
            MenuID INT,
            Price DECIMAL(8,2)
        );

        INSERT INTO @RestaurantMenu (RowNum, MenuID, Price)
        SELECT
            ROW_NUMBER() OVER (ORDER BY MenuID),
            MenuID,
            Price
        FROM Menu
        WHERE RestaurantID = @GeneratedRestaurantID;

        DECLARE @MenuCount INT = (SELECT COUNT(*) FROM @RestaurantMenu);
        DECLARE @MenuID1 INT;
        DECLARE @MenuID2 INT;
        DECLARE @Price1 DECIMAL(8,2);
        DECLARE @Price2 DECIMAL(8,2);
        DECLARE @Qty1 INT = CASE WHEN @OrderSequence % 4 = 0 THEN 2 ELSE 1 END;
        DECLARE @Qty2 INT = CASE WHEN @OrderSequence % 7 = 0 THEN 3 ELSE 1 END;

        SELECT @MenuID1 = MenuID, @Price1 = Price
        FROM @RestaurantMenu
        WHERE RowNum = ((@OrderSequence - 1) % @MenuCount) + 1;

        SELECT @MenuID2 = MenuID, @Price2 = Price
        FROM @RestaurantMenu
        WHERE RowNum = ((@OrderSequence + 1) % @MenuCount) + 1;

        INSERT INTO OrderDetails (OrderID, MenuID, Quantity)
        VALUES
            (@GeneratedOrderID, @MenuID1, @Qty1),
            (@GeneratedOrderID, @MenuID2, @Qty2);

        DECLARE @Subtotal DECIMAL(8,2) =
            (@Price1 * @Qty1) + (@Price2 * @Qty2);

        DECLARE @DeliveryFee DECIMAL(8,2) =
            CASE
                WHEN @Subtotal >= 30.00 THEN 0.00
                ELSE 3.99
            END;

        DECLARE @Tax DECIMAL(8,2) = ROUND(@Subtotal * 0.0725, 2);
        DECLARE @Total DECIMAL(8,2) = @Subtotal + @DeliveryFee + @Tax;

        UPDATE Orders
        SET OrderTotal = @Total
        WHERE OrderID = @GeneratedOrderID;

        DELETE FROM @RestaurantMenu;

        FETCH NEXT FROM OrderCursor
        INTO @OrderSequence, @GeneratedOrderID, @GeneratedRestaurantID;
    END;

    CLOSE OrderCursor;
    DEALLOCATE OrderCursor;

    /* ============================================================
       TRACKING RECORDS
       ============================================================ */

    INSERT INTO OrderTracking (OrderID, CurrentStatus, ETA, LastUpdated)
    SELECT
        O.OrderID,
        O.OrderStatus,
        CASE O.OrderStatus
            WHEN 'Placed' THEN 45
            WHEN 'Confirmed' THEN 38
            WHEN 'Preparing' THEN 25
            WHEN 'Out for Delivery' THEN 12
            WHEN 'Delivered' THEN 0
            WHEN 'Cancelled' THEN NULL
            ELSE 30
        END,
        CASE
            WHEN O.OrderStatus IN ('Delivered', 'Cancelled')
                THEN DATEADD(MINUTE, 35, O.OrderDate)
            ELSE DATEADD(MINUTE, 5, O.OrderDate)
        END
    FROM Orders O
    INNER JOIN Users U ON U.UserID = O.CustomerID
    WHERE U.Email LIKE '%@delidash.test';

    /* ============================================================
       TRANSACTIONS
       ============================================================ */

    INSERT INTO Transactions
        (OrderID, Amount, PaymentMethod, PaymentStatus)
    SELECT
        O.OrderID,
        O.OrderTotal,
        CASE O.OrderID % 4
            WHEN 0 THEN 'Visa'
            WHEN 1 THEN 'Mastercard'
            WHEN 2 THEN 'Apple Pay'
            ELSE 'Google Pay'
        END,
        CASE
            WHEN O.OrderStatus = 'Cancelled' THEN 'Refunded'
            WHEN O.OrderStatus = 'Placed' THEN 'Pending'
            ELSE 'Completed'
        END
    FROM Orders O
    INNER JOIN Users U ON U.UserID = O.CustomerID
    WHERE U.Email LIKE '%@delidash.test';

    COMMIT TRANSACTION;

    PRINT 'DeliDash test data created successfully.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO

/* ================================================================
   VERIFICATION QUERIES
   ================================================================ */

SELECT 'Roles' AS TableName, COUNT(*) AS RecordCount FROM Role
UNION ALL
SELECT 'Addresses', COUNT(*) FROM Address
UNION ALL
SELECT 'Images', COUNT(*) FROM Images
UNION ALL
SELECT 'Test Users', COUNT(*) FROM Users WHERE Email LIKE '%@delidash.test'
UNION ALL
SELECT 'Test Drivers', COUNT(*)
FROM Drivers D
JOIN Users U ON U.UserID = D.UserID
WHERE U.Email LIKE '%@delidash.test'
UNION ALL
SELECT 'Test Restaurants', COUNT(*)
FROM Restaurants R
JOIN Users U ON U.UserID = R.OwnerID
WHERE U.Email LIKE '%@delidash.test'
UNION ALL
SELECT 'Test Menu Items', COUNT(*)
FROM Menu M
JOIN Restaurants R ON R.RestaurantID = M.RestaurantID
JOIN Users U ON U.UserID = R.OwnerID
WHERE U.Email LIKE '%@delidash.test'
UNION ALL
SELECT 'Test Orders', COUNT(*)
FROM Orders O
JOIN Users U ON U.UserID = O.CustomerID
WHERE U.Email LIKE '%@delidash.test';

SELECT TOP 25
    O.OrderID,
    C.FirstName + ' ' + C.LastName AS Customer,
    R.Name AS Restaurant,
    DUser.FirstName + ' ' + DUser.LastName AS Driver,
    O.OrderStatus,
    O.OrderTotal,
    O.OrderDate
FROM Orders O
INNER JOIN Users C ON C.UserID = O.CustomerID
INNER JOIN Restaurants R ON R.RestaurantID = O.RestaurantID
LEFT JOIN Drivers D ON D.DriverID = O.DriverID
LEFT JOIN Users DUser ON DUser.UserID = D.UserID
WHERE C.Email LIKE '%@delidash.test'
ORDER BY O.OrderDate DESC;
GO