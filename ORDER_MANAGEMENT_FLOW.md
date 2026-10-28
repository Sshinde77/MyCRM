# Order Management: Screen Flow, Forms and APIs

This document describes the current Order Management module in the CRM. It is based on the current web screens, web routes, database structure and the API endpoints in routes/api.php.

## 1. Module purpose

Order Management tracks the complete operational journey:

1. An order is created for a client.
2. The order is assigned to an internal owner.
3. Items are purchased from a vendor.
4. Purchased quantities are received, either partially or fully.
5. Received goods are prepared for delivery.
6. Goods are dispatched to the client.
7. Delivery is marked complete.
8. The order becomes completed when purchase and delivery are both complete.

The purchase and delivery tracks are stored independently, while overall_status provides the combined order state.

## 2. Access and permissions

All API endpoints require a Sanctum bearer token:

    Authorization: Bearer <token>
    Accept: application/json
    Content-Type: application/json

The same permission names are used by the web and API routes:

| Permission | Allows |
|---|---|
| view_orders | View the order list, order details and form options |
| create_orders | Create an order |
| edit_orders | Edit an order, change workflow statuses, hold/resume |
| delete_orders | Delete an order or cancel an order |

Staff users see orders where they are the owner or creator. Admin, super admin and manager users can see all orders.

## 3. Order status model

### Purchase status

The purchase track uses these statuses:

1. Draft — order has been created but not placed with the vendor.
2. Ordered — order has been placed with the vendor.
3. Partially Received — some item quantities have been received.
4. Received — every item has been received in full.

### Delivery status

The delivery track uses these statuses:

1. Pending — goods are not yet ready for delivery.
2. Ready to Dispatch — goods are ready to leave the company.
3. Dispatched — goods have been sent to the client.
4. Partially Delivered — supported as a status value by the database/API, but there is currently no web button for it.
5. Delivered — delivery has been completed.

### Overall status

| Condition | Overall status |
|---|---|
| New active order | Open |
| Purchase is Received and delivery is Delivered | Completed |
| User cancels the order | Cancelled |

An order cannot be transitioned while it is cancelled or on hold. Delivery cannot be advanced to Ready to Dispatch, Dispatched or Delivered until at least part of the purchase is received.

## 4. Orders workspace screen

Web URL: /orders

### Header

- Add New Order — opens the create order screen.
- It is shown only to users with create_orders.

### Summary cards

The screen displays:

- All Orders
- Open
- On Hold
- Completed

The API returns the same values under data.stats.

### Filter form

| Field | Name | Required | Behavior |
|---|---|---:|---|
| Search | search | No | Searches order number, product name, client name or vendor name |
| Purchase status | purchase_status | No | Draft, Ordered, Partially Received, Received |
| Delivery status | delivery_status | No | Pending, Ready to Dispatch, Dispatched, Delivered |
| Priority | priority | No | High or Normal |
| Filter button | — | — | Applies selected filters |
| Clear button | — | — | Removes filters and returns to the default list |

The web search field also submits automatically after typing pauses. Select fields submit when changed.

### Quick tabs

- All — all visible orders.
- My orders — orders assigned to the current user.
- Due soon — vendor or client dates within the next seven days.
- Overdue — vendor or client date has passed while its track is incomplete.
- Completed — overall status is Completed.
- Cancelled — overall status is Cancelled.

### Order table

| Column | Data |
|---|---|
| Order | Order number, priority and overdue badge |
| Client / vendor | Client name and vendor name |
| Items | First product, quantity/unit or number of additional items |
| Dates | Vendor expected date and client delivery date |
| Purchase | Current purchase status |
| Delivery | Current delivery status |
| Owner | Assigned internal user |
| Action | View, Edit and Delete icons, depending on permissions |

### Row buttons

- View — opens the order detail screen.
- Edit — opens the edit form; requires edit_orders.
- Delete — soft-deletes the order after confirmation; requires delete_orders.

## 5. Create Order screen

Web URL: /orders/create

Permission: create_orders

### Order details form

| Visible field | Request name | Required | Rules |
|---|---|---:|---|
| Client | client_id | Yes | Must exist in users and represent a client |
| Vendor | vendor_id | Yes | Must exist in vendors |
| Assigned to | assigned_user_id | No | Must exist in users; defaults to current user |
| Order date | order_date | Yes | Valid date |
| Priority | priority | Yes | Normal or High |
| Vendor expected date | vendor_expected_date | Yes | Must be on or after order_date |
| Client delivery date | client_delivery_date | Yes | Must be on or after vendor expected date |
| Notes | notes | No | Text/internal instructions |
| Already placed with vendor | already_placed | No | Boolean; starts purchase status as Ordered when true |

### Order item form

The screen starts with one item and has an Add item button. Each row has:

| Field | Request name | Required | Rules |
|---|---|---:|---|
| Product name | items[index][product_name] | Yes | Maximum 255 characters |
| Quantity | items[index][quantity] | Yes | Numeric, minimum 0.001 |
| Unit | items[index][unit] | No | Maximum 30 characters |
| Purchase rate | items[index][purchase_rate] | No | Numeric, minimum 0 |
| Selling rate | items[index][selling_rate] | No | Numeric, minimum 0; accepted by the API |
| Remarks | items[index][remarks] | No | Maximum 255 characters; accepted by the API |

The web form shows a Remove item button for each row, but it keeps at least one item row.

### Create button behavior

When submitted:

1. A unique order number is generated in the format ORD-YYYY-####.
2. The order is assigned to the selected user or current user.
3. Purchase status is Draft, unless already_placed is true.
4. Delivery status is Pending.
5. Overall status is Open.
6. All item rows are saved.
7. An Order / Created history record is saved.
8. If already placed, a Purchase / Ordered history record is also saved.

## 6. Edit Order screen

Web URL: /orders/{order}/edit

Permission: edit_orders

The edit screen contains the same order detail and item fields as create:

- client_id
- vendor_id
- assigned_user_id
- order_date
- priority
- vendor_expected_date
- client_delivery_date
- notes
- items[] with product, quantity, unit, purchase rate, selling rate and remarks

The existing workflow statuses are preserved. Saving replaces the existing item rows with the submitted item rows and adds an Order / Updated history entry.

Button:

- Save changes — validates and updates the order.

## 7. Order detail screen

Web URL: /orders/{order}

### Header buttons

When the order is open:

- Put on hold — changes is_on_hold to true.
- Resume — changes is_on_hold to false.
- Cancel — opens the cancellation form.

The hold/resume button requires edit_orders. The cancel button requires delete_orders.

### Vendor and client cards

The detail page shows:

- Vendor name
- Vendor expected date
- Vendor received date, when available
- Client name
- Client delivery date
- Client delivered date, when available

### Purchase workflow buttons

The purchase card shows:

Draft → Ordered → Partially Received → Received

Buttons:

1. Mark as ordered
   - Visible when purchase status is Draft.
   - Changes purchase status to Ordered.

2. Record receipt
   - Visible after the order is placed and before it is fully received.
   - Opens a modal with one received quantity field per order item.
   - Changes purchase status to Partially Received.

3. Mark all received
   - Visible while purchase status is not Received.
   - Sets each item received quantity to its ordered quantity.
   - Changes purchase status to Received.

Receipt quantity rules:

- Received quantity cannot be negative.
- Received quantity cannot exceed ordered quantity.
- To mark the purchase fully received, every item must be received in full.

### Delivery workflow buttons

The delivery card shows:

Pending → Ready to Dispatch → Dispatched → Delivered

Buttons:

1. Mark Ready to Dispatch
2. Mark Dispatched
3. Mark delivered

Only the next valid transition is shown. Delivery cannot progress until at least part of the purchase has been received.

### Items and progress

The items table contains:

- Product
- Unit
- Ordered quantity
- Received quantity
- Delivered quantity
- Progress percentage

The current web workflow updates received quantities. Delivered quantity is stored in the database and returned by the API, but there is currently no separate web button/form for editing it.

### Order information

The detail sidebar shows:

- Order date
- Owner
- Vendor expected date
- Client delivery date
- Internal notes
- Activity history

### Cancel form

| Field | Name | Required | Rules |
|---|---|---:|---|
| Cancellation reason | cancel_reason | Yes | Text, maximum 1000 characters |

Submitting cancellation:

1. Sets overall status to Cancelled.
2. Stores the cancellation reason.
3. Stores cancelling user and timestamp.
4. Adds an Order / Cancelled history entry.

## 8. API endpoint catalogue

Base URL:

    /api/v1/orders

All responses use this format:

    {
      "success": true,
      "message": "Message",
      "data": {}
    }

Validation or business-rule failures return an error response with HTTP status 422.

### Reference and list APIs

| Method | Endpoint | Permission | Used by |
|---|---|---|---|
| GET | /form-options | view_orders | Create/edit dropdowns and status controls |
| GET | / | view_orders | Orders workspace |
| GET | /{order} | view_orders | Order detail screen |

List query parameters:

    search
    purchase_status
    delivery_status
    priority
    overall_status
    assigned_user_id
    client_id
    vendor_id
    tab=mine|due|completed|cancelled
    overdue=1
    order_date_from
    order_date_to
    vendor_date_from
    vendor_date_to
    client_date_from
    client_date_to
    page
    per_page

The list response includes paginated orders and stats.

### Order CRUD APIs

| Method | Endpoint | Permission | Purpose |
|---|---|---|---|
| POST | / | create_orders | Create order and items |
| PUT/PATCH | /{order} | edit_orders | Replace order details and items |
| DELETE | /{order} | delete_orders | Soft-delete order |

Create/update JSON example:

    {
      "client_id": 15,
      "vendor_id": 4,
      "assigned_user_id": 8,
      "order_date": "2026-10-27",
      "vendor_expected_date": "2026-10-30",
      "client_delivery_date": "2026-11-02",
      "priority": "High",
      "notes": "Deliver during business hours.",
      "already_placed": false,
      "items": [
        {
          "product_name": "Product A",
          "quantity": 10,
          "unit": "pcs",
          "purchase_rate": 125.50,
          "selling_rate": 175.00,
          "remarks": "Blue variant"
        }
      ]
    }

### Workflow action APIs

| Method | Endpoint | Permission | Button/flow |
|---|---|---|---|
| POST | /{order}/status | edit_orders | Generic status transition |
| POST | /{order}/purchase/order | edit_orders | Mark as ordered |
| POST | /{order}/purchase/receipt | edit_orders | Record partial receipt |
| POST | /{order}/purchase/receive | edit_orders | Mark all received |
| POST | /{order}/delivery/ready | edit_orders | Mark ready to dispatch |
| POST | /{order}/delivery/dispatch | edit_orders | Mark dispatched |
| POST | /{order}/delivery/deliver | edit_orders | Mark delivered |
| POST | /{order}/hold | edit_orders | Put on hold or resume |
| POST | /{order}/cancel | delete_orders | Cancel order |

Generic status request:

    {
      "track": "Purchase",
      "status": "Partially Received",
      "date": "2026-10-30",
      "remark": "Two cartons received.",
      "received": {
        "101": 5,
        "102": 2
      }
    }

Record receipt request:

    {
      "received": {
        "101": 5,
        "102": 2
      },
      "date": "2026-10-30",
      "remark": "Partial shipment received."
    }

Hold/resume request:

    {
      "remark": "Waiting for client confirmation."
    }

Cancel request:

    {
      "cancel_reason": "Client cancelled the requirement."
    }

## 9. Screen-to-API mapping

| Screen | APIs required |
|---|---|
| Orders list | GET /orders, GET /orders/form-options, GET /orders/{id} for view |
| Create order | GET /orders/form-options, POST /orders |
| Edit order | GET /orders/form-options, GET /orders/{id}, PUT/PATCH /orders/{id} |
| Order detail | GET /orders/{id} |
| Mark as ordered | POST /orders/{id}/purchase/order |
| Record receipt modal | POST /orders/{id}/purchase/receipt |
| Mark all received | POST /orders/{id}/purchase/receive |
| Ready for dispatch | POST /orders/{id}/delivery/ready |
| Dispatch | POST /orders/{id}/delivery/dispatch |
| Delivered | POST /orders/{id}/delivery/deliver |
| Hold/resume | POST /orders/{id}/hold |
| Cancel modal | POST /orders/{id}/cancel |
| Delete from list | DELETE /orders/{id} |

## 10. Data returned for an order

The order response includes:

- id
- order_no
- client_id, client relationship and client_name
- vendor_id and vendor relationship
- assigned_user_id and owner relationship
- order_date
- vendor_expected_date
- vendor_received_date
- client_delivery_date
- client_delivered_date
- purchase_status
- delivery_status
- overall_status
- is_on_hold
- priority
- notes
- cancellation fields
- timestamps
- items
- is_overdue
- overdue_legs

The detail endpoint additionally includes:

- creator
- activity history and history users
- attachments

## 11. Important implementation notes

1. Deleting an order is a soft delete; its database row is not permanently removed.
2. Order numbers are generated by the server and must not be supplied by the client.
3. Status changes create history records.
4. The API validates all date ordering rules.
5. The API uses the same staff visibility rule as the web module.
6. Partially Delivered exists in the data model/API status list, but the current web screen does not expose a button for it.
7. The current web screen displays delivered quantity but does not provide a delivery-quantity entry form. A future partial-delivery feature would need an item delivery quantity API and a corresponding UI.
