import csv
import random
from datetime import date, timedelta
from pathlib import Path

random.seed(42)

CUSTOMERS = [
    ("C001", "(주)한국무역"),
    ("C002", "삼성전자 협력사"),
    ("C003", "현대상사"),
    ("C004", "LG유통"),
    ("C005", "SK네트웍스"),
    ("C006", "롯데글로벌"),
    ("C007", "GS리테일"),
    ("C008", "포스코인터내셔널"),
    ("C009", "한화솔루션"),
    ("C010", "두산중공업"),
    ("C011", "CJ제일제당"),
    ("C012", "코오롱인더스트리"),
    ("C013", "효성그룹"),
    ("C014", "OCI주식회사"),
    ("C015", "태광산업"),
]

MANAGERS = ["김민준", "이서연", "박지호", "최유진", "정수민", "한아름", "오태양", "임지수"]
DEPARTMENTS = ["영업1팀", "영업2팀", "영업3팀", "수출팀", "국내영업팀", "특판팀"]
CURRENCIES = ["KRW", "USD", "EUR", "JPY"]


def get_status(days_outstanding: int) -> str:
    if days_outstanding <= 0:
        return "정상"
    elif days_outstanding <= 30:
        return "주의"
    elif days_outstanding <= 90:
        return "연체"
    else:
        return "위험"


def generate_records(n: int = 500) -> list[dict]:
    records = []
    today = date.today()

    for i in range(1, n + 1):
        customer_code, customer_name = random.choice(CUSTOMERS)
        invoice_date = today - timedelta(days=random.randint(1, 365))
        due_date = invoice_date + timedelta(days=random.choice([30, 45, 60, 90]))
        invoice_amount = round(random.uniform(500_000, 50_000_000), -3)

        # 일부는 부분 수금, 일부는 미수금 0, 일부는 전혀 수금 안 됨
        collect_rate = random.choices(
            [0.0, random.uniform(0.1, 0.9), 1.0],
            weights=[0.3, 0.4, 0.3],
        )[0]
        received_amount = round(invoice_amount * collect_rate, -3)
        outstanding_amount = invoice_amount - received_amount

        days_outstanding = max(0, (today - due_date).days)
        currency = random.choices(CURRENCIES, weights=[0.7, 0.15, 0.1, 0.05])[0]

        records.append({
            "거래처코드": customer_code,
            "거래처명": customer_name,
            "청구번호": f"INV-2024-{i:05d}",
            "청구일자": invoice_date.isoformat(),
            "만기일자": due_date.isoformat(),
            "통화": currency,
            "청구금액": int(invoice_amount),
            "수금금액": int(received_amount),
            "미수금액": int(outstanding_amount),
            "미수일수": days_outstanding,
            "미수상태": get_status(days_outstanding),
            "담당자": random.choice(MANAGERS),
            "담당부서": random.choice(DEPARTMENTS),
            "비고": "",
        })

    return records


def main():
    output_path = Path(__file__).parent / "ar_data.csv"
    records = generate_records(500)

    fieldnames = [
        "거래처코드", "거래처명", "청구번호", "청구일자", "만기일자",
        "통화", "청구금액", "수금금액", "미수금액", "미수일수",
        "미수상태", "담당자", "담당부서", "비고",
    ]

    with open(output_path, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(records)

    print(f"생성 완료: {output_path} ({len(records)}건)")
    status_counts = {}
    for r in records:
        status_counts[r["미수상태"]] = status_counts.get(r["미수상태"], 0) + 1
    for status, count in sorted(status_counts.items()):
        print(f"  {status}: {count}건")


if __name__ == "__main__":
    main()
