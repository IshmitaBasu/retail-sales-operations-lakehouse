"""Generate deterministic initial or updated retail source snapshots."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import random
from datetime import date, datetime, time, timedelta
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from typing import Any


SEED = 20261102
INITIAL_CUSTOMER_COUNT = 2_000
INITIAL_PRODUCT_COUNT = 500
INITIAL_ORDER_COUNT = 20_000
UPDATED_ORDER_COUNT = 800
ADVANCED_ORDER_COUNT = 250
MODIFIED_LINE_COUNT = 100

REPORTING_START = datetime(2024, 1, 1)
INITIAL_ORDER_END = datetime(2025, 11, 30, 23, 59, 59)
UPDATED_ORDER_START = datetime(2025, 12, 1)
UPDATED_ORDER_END = datetime(2025, 12, 31, 23, 59, 59)

MONEY_QUANTUM = Decimal("0.01")

CATEGORIES = (
    "Books",
    "Clothing",
    "Electronics",
    "Grocery",
    "Health & Beauty",
    "Home",
    "Office",
    "Pet Supplies",
    "Sports",
    "Toys",
)
REGIONS = ("North", "South", "East", "West")
CHANNELS = ("web", "mobile", "marketplace", "store")
CENTRES = (
    ("FC-NORTH", "Hamburg Centre", "North"),
    ("FC-SOUTH", "Munich Centre", "South"),
    ("FC-EAST", "Berlin Centre", "East"),
    ("FC-WEST", "Cologne Centre", "West"),
)
CARRIERS = ("DHL", "DPD", "GLS", "Hermes")

CUSTOMER_COLUMNS = (
    "customer_id",
    "signup_date",
    "customer_segment",
    "region",
    "country_code",
    "updated_at",
)
PRODUCT_COLUMNS = (
    "product_id",
    "product_name",
    "category",
    "product_type",
    "unit_cost_eur",
    "list_price_eur",
    "is_active",
    "updated_at",
)
ORDER_COLUMNS = (
    "order_id",
    "customer_id",
    "order_created_at",
    "order_type",
    "sales_channel",
    "payment_status",
    "order_status",
    "currency_code",
    "updated_at",
)
ORDER_LINE_COLUMNS = (
    "order_line_id",
    "order_id",
    "product_id",
    "quantity",
    "unit_price_eur",
    "discount_amount_eur",
    "updated_at",
)
FULFILMENT_COLUMNS = (
    "fulfilment_id",
    "order_id",
    "fulfilment_centre_id",
    "fulfilment_centre_name",
    "fulfilment_centre_region",
    "carrier_name",
    "fulfilment_status",
    "picked_at",
    "packed_at",
    "shipped_at",
    "promised_delivery_date",
    "delivered_at",
    "updated_at",
)


def money(value: Decimal) -> str:
    return str(value.quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP))


def parse_money(value: str) -> Decimal:
    return Decimal(value)


def iso_timestamp(value: datetime | None) -> str:
    return value.strftime("%Y-%m-%d %H:%M:%S") if value else ""


def parse_timestamp(value: str) -> datetime | None:
    return datetime.strptime(value, "%Y-%m-%d %H:%M:%S") if value else None


def random_datetime(rng: random.Random, start: datetime, end: datetime) -> datetime:
    seconds = int((end - start).total_seconds())
    return start + timedelta(seconds=rng.randint(0, seconds))


def build_customers(rng: random.Random) -> list[dict[str, str]]:
    customers: list[dict[str, str]] = []
    signup_start = date(2022, 1, 1)
    signup_span = (date(2023, 12, 31) - signup_start).days

    for index in range(1, INITIAL_CUSTOMER_COUNT + 1):
        signup_date = signup_start + timedelta(days=rng.randint(0, signup_span))
        customers.append(
            {
                "customer_id": f"CUS-{index:05d}",
                "signup_date": signup_date.isoformat(),
                "customer_segment": rng.choices(
                    ("consumer", "small_business"), weights=(88, 12), k=1
                )[0],
                "region": rng.choice(REGIONS),
                "country_code": "DE",
                "updated_at": iso_timestamp(datetime.combine(signup_date, time(9))),
            }
        )

    return customers


def build_products(rng: random.Random) -> list[dict[str, str]]:
    products: list[dict[str, str]] = []

    for index in range(1, INITIAL_PRODUCT_COUNT + 1):
        product_type = "digital" if index % 10 == 0 else "physical"
        category = rng.choice(("Books", "Electronics")) if product_type == "digital" else rng.choice(CATEGORIES)
        unit_cost = Decimal(rng.randint(250, 18_000)) / Decimal(100)
        markup = Decimal(rng.randint(140, 260)) / Decimal(100)
        list_price = (unit_cost * markup).quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP)
        created_at = datetime(2023, 1, 1) + timedelta(days=index % 365)

        products.append(
            {
                "product_id": f"PRD-{index:04d}",
                "product_name": f"{category} Product {index:04d}",
                "category": category,
                "product_type": product_type,
                "unit_cost_eur": money(unit_cost),
                "list_price_eur": money(list_price),
                "is_active": "false" if index % 47 == 0 else "true",
                "updated_at": iso_timestamp(created_at),
            }
        )

    return products


def choose_order_status(rng: random.Random) -> str:
    return rng.choices(
        ("placed", "processing", "shipped", "delivered", "cancelled"),
        weights=(3, 7, 8, 72, 10),
        k=1,
    )[0]


def payment_status_for(rng: random.Random, order_status: str) -> str:
    if order_status == "cancelled":
        return rng.choices(("refunded", "failed", "paid"), weights=(45, 25, 30), k=1)[0]
    return rng.choices(("paid", "pending"), weights=(95, 5), k=1)[0]


def status_update_delay(order_status: str) -> timedelta:
    return {
        "placed": timedelta(hours=1),
        "processing": timedelta(hours=24),
        "shipped": timedelta(days=3),
        "delivered": timedelta(days=8),
        "cancelled": timedelta(days=2),
    }[order_status]


def build_fulfilment(
    rng: random.Random,
    order: dict[str, str],
    fulfilment_number: int,
) -> dict[str, str] | None:
    if order["order_type"] == "digital":
        return None

    order_status = order["order_status"]
    if order_status == "cancelled" and rng.random() > 0.30:
        return None

    created_at = parse_timestamp(order["order_created_at"])
    assert created_at is not None
    picked_at = created_at + timedelta(hours=rng.randint(4, 30))
    packed_at = picked_at + timedelta(hours=rng.randint(1, 10))
    shipped_at = packed_at + timedelta(hours=rng.randint(2, 24))
    promised_date = (created_at + timedelta(days=rng.randint(3, 7))).date()
    promised_delivery_at = datetime.combine(
        promised_date + timedelta(days=rng.choices((-1, 0, 1, 2), weights=(20, 60, 15, 5), k=1)[0]),
        time(hour=rng.randint(9, 20), minute=rng.choice((0, 15, 30, 45))),
    )
    delivered_at = max(promised_delivery_at, shipped_at + timedelta(hours=1))
    centre_id, centre_name, centre_region = rng.choice(CENTRES)

    if order_status == "placed":
        fulfilment_status = "processing"
        picked_at = packed_at = shipped_at = delivered_at = None
    elif order_status == "processing":
        fulfilment_status = "picked"
        packed_at = shipped_at = delivered_at = None
    elif order_status == "shipped":
        fulfilment_status = "shipped"
        delivered_at = None
    elif order_status == "delivered":
        fulfilment_status = "delivered"
    else:
        fulfilment_status = "cancelled"
        if rng.random() < 0.5:
            packed_at = shipped_at = delivered_at = None
        else:
            picked_at = packed_at = shipped_at = delivered_at = None

    event_timestamps = [value for value in (picked_at, packed_at, shipped_at, delivered_at) if value]
    updated_at = max(event_timestamps, default=parse_timestamp(order["updated_at"]))
    assert updated_at is not None

    return {
        "fulfilment_id": f"FUL-{fulfilment_number:06d}",
        "order_id": order["order_id"],
        "fulfilment_centre_id": centre_id,
        "fulfilment_centre_name": centre_name,
        "fulfilment_centre_region": centre_region,
        "carrier_name": rng.choice(CARRIERS),
        "fulfilment_status": fulfilment_status,
        "picked_at": iso_timestamp(picked_at),
        "packed_at": iso_timestamp(packed_at),
        "shipped_at": iso_timestamp(shipped_at),
        "promised_delivery_date": promised_date.isoformat(),
        "delivered_at": iso_timestamp(delivered_at),
        "updated_at": iso_timestamp(updated_at),
    }


def append_orders(
    *,
    rng: random.Random,
    order_count: int,
    first_order_number: int,
    first_line_number: int,
    first_fulfilment_number: int,
    order_start: datetime,
    order_end: datetime,
    customers: list[dict[str, str]],
    products: list[dict[str, str]],
    orders: list[dict[str, str]],
    order_lines: list[dict[str, str]],
    fulfilments: list[dict[str, str]],
) -> tuple[int, int]:
    physical_products = [product for product in products if product["product_type"] == "physical"]
    digital_products = [product for product in products if product["product_type"] == "digital"]
    line_number = first_line_number
    fulfilment_number = first_fulfilment_number

    for offset in range(order_count):
        order_number = first_order_number + offset
        order_created_at = random_datetime(rng, order_start, order_end)
        order_type = rng.choices(("physical", "digital"), weights=(90, 10), k=1)[0]
        order_status = choose_order_status(rng)
        order_updated_at = order_created_at + status_update_delay(order_status)
        order = {
            "order_id": f"ORD-{order_number:06d}",
            "customer_id": rng.choice(customers)["customer_id"],
            "order_created_at": iso_timestamp(order_created_at),
            "order_type": order_type,
            "sales_channel": rng.choices(CHANNELS, weights=(48, 30, 12, 10), k=1)[0],
            "payment_status": payment_status_for(rng, order_status),
            "order_status": order_status,
            "currency_code": "EUR",
            "updated_at": iso_timestamp(order_updated_at),
        }
        orders.append(order)

        product_pool = physical_products if order_type == "physical" else digital_products
        line_count = rng.choices((1, 2, 3, 4, 5), weights=(10, 25, 35, 22, 8), k=1)[0]
        selected_products = rng.sample(product_pool, k=line_count)

        for product in selected_products:
            quantity = rng.randint(1, 5)
            list_price = parse_money(product["list_price_eur"])
            price_multiplier = Decimal(rng.randint(90, 105)) / Decimal(100)
            unit_price = (list_price * price_multiplier).quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP)
            gross_amount = unit_price * quantity
            discount_rate = Decimal(rng.choice((0, 0, 0, 5, 10, 15, 20))) / Decimal(100)
            discount_amount = (gross_amount * discount_rate).quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP)
            line_updated_at = min(
                order_updated_at,
                order_created_at + timedelta(hours=rng.randint(0, 24)),
            )
            order_lines.append(
                {
                    "order_line_id": f"LIN-{line_number:07d}",
                    "order_id": order["order_id"],
                    "product_id": product["product_id"],
                    "quantity": str(quantity),
                    "unit_price_eur": money(unit_price),
                    "discount_amount_eur": money(discount_amount),
                    "updated_at": iso_timestamp(line_updated_at),
                }
            )
            line_number += 1

        fulfilment = build_fulfilment(rng, order, fulfilment_number)
        if fulfilment:
            fulfilments.append(fulfilment)
            fulfilment_number += 1

    return line_number, fulfilment_number


def build_initial_snapshot() -> dict[str, list[dict[str, str]]]:
    rng = random.Random(SEED)
    customers = build_customers(rng)
    products = build_products(rng)
    orders: list[dict[str, str]] = []
    order_lines: list[dict[str, str]] = []
    fulfilments: list[dict[str, str]] = []

    append_orders(
        rng=rng,
        order_count=INITIAL_ORDER_COUNT,
        first_order_number=1,
        first_line_number=1,
        first_fulfilment_number=1,
        order_start=REPORTING_START,
        order_end=INITIAL_ORDER_END,
        customers=customers,
        products=products,
        orders=orders,
        order_lines=order_lines,
        fulfilments=fulfilments,
    )

    return {
        "customers": customers,
        "products": products,
        "orders": orders,
        "order_lines": order_lines,
        "fulfilments": fulfilments,
    }


def progress_fulfilment(
    fulfilment: dict[str, str],
    order: dict[str, str],
    new_status: str,
    update_index: int,
) -> None:
    created_at = parse_timestamp(order["order_created_at"])
    assert created_at is not None
    picked_at = created_at + timedelta(hours=12 + update_index % 8)
    packed_at = picked_at + timedelta(hours=4)
    shipped_at = packed_at + timedelta(hours=8)
    promised_date = date.fromisoformat(fulfilment["promised_delivery_date"])
    delivered_date = promised_date + timedelta(days=1 if update_index % 6 == 0 else 0)
    delivered_at = max(
        datetime.combine(delivered_date, time(hour=16)),
        shipped_at + timedelta(hours=1),
    )

    if new_status == "processing":
        fulfilment_status = "picked"
        packed_at = shipped_at = delivered_at = None
    elif new_status == "shipped":
        fulfilment_status = "shipped"
        delivered_at = None
    else:
        fulfilment_status = "delivered"

    fulfilment.update(
        {
            "fulfilment_status": fulfilment_status,
            "picked_at": iso_timestamp(picked_at),
            "packed_at": iso_timestamp(packed_at),
            "shipped_at": iso_timestamp(shipped_at),
            "delivered_at": iso_timestamp(delivered_at),
            "updated_at": order["updated_at"],
        }
    )


def apply_updates(data: dict[str, list[dict[str, str]]]) -> dict[str, Any]:
    rng = random.Random(SEED + 1)
    orders = data["orders"]
    order_lines = data["order_lines"]
    fulfilments = data["fulfilments"]
    fulfilment_by_order = {row["order_id"]: row for row in fulfilments}

    candidates = [
        order
        for order in orders
        if order["order_type"] == "physical"
        and order["order_status"] in {"placed", "processing", "shipped"}
        and parse_timestamp(order["order_created_at"]) >= datetime(2025, 9, 1)
        and order["order_id"] in fulfilment_by_order
    ]
    candidates.sort(key=lambda row: row["order_id"])
    if len(candidates) < ADVANCED_ORDER_COUNT:
        raise ValueError("Not enough deterministic orders are available for status progression")

    advanced_orders = rng.sample(candidates, ADVANCED_ORDER_COUNT)
    status_progression = {"placed": "processing", "processing": "shipped", "shipped": "delivered"}

    for index, order in enumerate(sorted(advanced_orders, key=lambda row: row["order_id"])):
        new_status = status_progression[order["order_status"]]
        updated_at = datetime(2025, 12, 15) + timedelta(
            days=index % 16,
            hours=index % 8,
        )
        order["order_status"] = new_status
        order["payment_status"] = "paid"
        order["updated_at"] = iso_timestamp(updated_at)
        progress_fulfilment(
            fulfilment_by_order[order["order_id"]], order, new_status, index
        )

    eligible_lines = [
        line
        for line in order_lines
        if parse_timestamp(line["updated_at"]) < datetime(2025, 12, 1)
    ]
    modified_lines = rng.sample(eligible_lines, MODIFIED_LINE_COUNT)

    for index, line in enumerate(sorted(modified_lines, key=lambda row: row["order_line_id"])):
        gross_amount = parse_money(line["unit_price_eur"]) * int(line["quantity"])
        old_discount = parse_money(line["discount_amount_eur"])
        additional_discount = (gross_amount * Decimal("0.05")).quantize(
            MONEY_QUANTUM, rounding=ROUND_HALF_UP
        )
        maximum_discount = (gross_amount * Decimal("0.30")).quantize(
            MONEY_QUANTUM, rounding=ROUND_HALF_UP
        )
        line["discount_amount_eur"] = money(
            min(old_discount + additional_discount, maximum_discount)
        )
        line["updated_at"] = iso_timestamp(
            datetime(2025, 12, 28, 8) + timedelta(minutes=index)
        )

    first_line_number = len(order_lines) + 1
    first_fulfilment_number = len(fulfilments) + 1
    append_orders(
        rng=rng,
        order_count=UPDATED_ORDER_COUNT,
        first_order_number=INITIAL_ORDER_COUNT + 1,
        first_line_number=first_line_number,
        first_fulfilment_number=first_fulfilment_number,
        order_start=UPDATED_ORDER_START,
        order_end=UPDATED_ORDER_END,
        customers=data["customers"],
        products=data["products"],
        orders=orders,
        order_lines=order_lines,
        fulfilments=fulfilments,
    )

    return {
        "added_order_ids": [
            f"ORD-{number:06d}"
            for number in range(INITIAL_ORDER_COUNT + 1, INITIAL_ORDER_COUNT + UPDATED_ORDER_COUNT + 1)
        ],
        "advanced_order_ids": sorted(order["order_id"] for order in advanced_orders),
        "modified_order_line_ids": sorted(line["order_line_id"] for line in modified_lines),
    }


def assert_unique(rows: list[dict[str, str]], key: str, table_name: str) -> None:
    values = [row[key] for row in rows]
    if len(values) != len(set(values)):
        raise ValueError(f"{table_name}.{key} is not unique")


def validate_snapshot(data: dict[str, list[dict[str, str]]]) -> None:
    customers = data["customers"]
    products = data["products"]
    orders = data["orders"]
    order_lines = data["order_lines"]
    fulfilments = data["fulfilments"]

    assert_unique(customers, "customer_id", "customers")
    assert_unique(products, "product_id", "products")
    assert_unique(orders, "order_id", "orders")
    assert_unique(order_lines, "order_line_id", "order_lines")
    assert_unique(fulfilments, "fulfilment_id", "fulfilments")
    assert_unique(fulfilments, "order_id", "fulfilments")

    customer_ids = {row["customer_id"] for row in customers}
    product_by_id = {row["product_id"]: row for row in products}
    order_by_id = {row["order_id"]: row for row in orders}

    if any(order["customer_id"] not in customer_ids for order in orders):
        raise ValueError("An order references an unknown customer")

    for line in order_lines:
        if line["order_id"] not in order_by_id:
            raise ValueError("An order line references an unknown order")
        if line["product_id"] not in product_by_id:
            raise ValueError("An order line references an unknown product")
        order = order_by_id[line["order_id"]]
        product = product_by_id[line["product_id"]]
        if order["order_type"] != product["product_type"]:
            raise ValueError("An order line product type does not match its order type")
        quantity = int(line["quantity"])
        gross_amount = parse_money(line["unit_price_eur"]) * quantity
        discount_amount = parse_money(line["discount_amount_eur"])
        if quantity <= 0 or discount_amount < 0 or discount_amount > gross_amount:
            raise ValueError("An order line violates quantity or discount bounds")

    for fulfilment in fulfilments:
        order = order_by_id.get(fulfilment["order_id"])
        if not order or order["order_type"] != "physical":
            raise ValueError("A fulfilment must reference a physical order")
        if fulfilment["fulfilment_status"] == "delivered" and not fulfilment["delivered_at"]:
            raise ValueError("A delivered fulfilment is missing delivered_at")
        timestamps = [
            parse_timestamp(fulfilment[field])
            for field in ("picked_at", "packed_at", "shipped_at", "delivered_at")
            if fulfilment[field]
        ]
        if timestamps != sorted(timestamps):
            raise ValueError("Fulfilment timestamps are out of order")

    if not 50_000 <= len(order_lines) <= 80_000:
        raise ValueError("Order-line volume is outside the architecture boundary")


def write_csv(path: Path, columns: tuple[str, ...], rows: list[dict[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_snapshot(
    output_dir: Path,
    snapshot_name: str,
    data: dict[str, list[dict[str, str]]],
    update_audit: dict[str, Any],
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    file_definitions = {
        "customers": CUSTOMER_COLUMNS,
        "products": PRODUCT_COLUMNS,
        "orders": ORDER_COLUMNS,
        "order_lines": ORDER_LINE_COLUMNS,
        "fulfilments": FULFILMENT_COLUMNS,
    }

    for table_name, columns in file_definitions.items():
        write_csv(output_dir / f"{table_name}.csv", columns, data[table_name])

    file_hashes = {
        f"{table_name}.csv": sha256(output_dir / f"{table_name}.csv")
        for table_name in file_definitions
    }
    manifest = {
        "snapshot": snapshot_name,
        "seed": SEED,
        "counts": {table_name: len(data[table_name]) for table_name in file_definitions},
        "order_date_min": min(row["order_created_at"] for row in data["orders"]),
        "order_date_max": max(row["order_created_at"] for row in data["orders"]),
        "update_audit": update_audit,
        "sha256": file_hashes,
    }
    with (output_dir / "snapshot_manifest.json").open("w", encoding="utf-8") as manifest_file:
        json.dump(manifest, manifest_file, indent=2, sort_keys=True)
        manifest_file.write("\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--snapshot",
        choices=("initial", "updated"),
        default="initial",
        help="Deterministic source state to generate.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "data" / "generated",
        help="Destination directory for generated files.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    data = build_initial_snapshot()
    update_audit: dict[str, Any] = {
        "added_order_ids": [],
        "advanced_order_ids": [],
        "modified_order_line_ids": [],
    }

    if args.snapshot == "updated":
        update_audit = apply_updates(data)

    validate_snapshot(data)
    write_snapshot(args.output_dir, args.snapshot, data, update_audit)

    print(f"Generated {args.snapshot} snapshot in {args.output_dir.resolve()}")
    for table_name in ("customers", "products", "orders", "order_lines", "fulfilments"):
        print(f"{table_name}: {len(data[table_name])}")
    if args.snapshot == "updated":
        print(f"added_orders: {len(update_audit['added_order_ids'])}")
        print(f"advanced_orders: {len(update_audit['advanced_order_ids'])}")
        print(f"modified_order_lines: {len(update_audit['modified_order_line_ids'])}")


if __name__ == "__main__":
    main()
