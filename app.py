import os
import pyodbc
from flask import Flask, render_template, request

app = Flask(__name__)
app.jinja_env.globals["enumerate"] = enumerate


def get_conn():
    server = os.environ["SQL_SERVER"]
    database = os.environ["SQL_DATABASE"]
    user = os.environ["SQL_USER"]
    password = os.environ["SQL_PASSWORD"]
    conn_str = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={server};DATABASE={database};"
        f"UID={user};PWD={password};"
        f"Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    )
    return pyodbc.connect(conn_str)


@app.route("/")
def index():
    status = request.args.get("status", "")
    dept = request.args.get("dept", "")
    manager = request.args.get("manager", "")
    customer = request.args.get("customer", "")
    min_days = request.args.get("min_days", "")

    where_clauses = []
    params = []

    if status:
        where_clauses.append("미수상태 = ?")
        params.append(status)
    if dept:
        where_clauses.append("담당부서 = ?")
        params.append(dept)
    if manager:
        where_clauses.append("담당자 = ?")
        params.append(manager)
    if customer:
        where_clauses.append("거래처명 LIKE ?")
        params.append(f"%{customer}%")
    if min_days:
        where_clauses.append("미수일수 >= ?")
        params.append(int(min_days))

    where_sql = "WHERE " + " AND ".join(where_clauses) if where_clauses else ""

    query = f"""
        SELECT
            거래처코드, 거래처명, 청구번호, 청구일자, 만기일자,
            통화, 청구금액, 수금금액, 미수금액, 미수일수,
            미수상태, 담당자, 담당부서, 비고
        FROM dbo.AR_RECEIVABLES
        {where_sql}
        ORDER BY 미수일수 DESC, 미수금액 DESC
    """

    summary_query = f"""
        SELECT
            미수상태,
            COUNT(*) AS 건수,
            SUM(미수금액) AS 미수합계
        FROM dbo.AR_RECEIVABLES
        {where_sql}
        GROUP BY 미수상태
        ORDER BY 미수상태
    """

    filter_query = """
        SELECT DISTINCT 미수상태 FROM dbo.AR_RECEIVABLES ORDER BY 미수상태
        SELECT DISTINCT 담당부서 FROM dbo.AR_RECEIVABLES ORDER BY 담당부서
        SELECT DISTINCT 담당자 FROM dbo.AR_RECEIVABLES ORDER BY 담당자
    """

    conn = get_conn()
    cursor = conn.cursor()

    cursor.execute(query, params)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]

    cursor.execute(summary_query, params)
    summary = cursor.fetchall()

    cursor.execute("SELECT DISTINCT 미수상태 FROM dbo.AR_RECEIVABLES ORDER BY 미수상태")
    statuses = [r[0] for r in cursor.fetchall()]

    cursor.execute("SELECT DISTINCT 담당부서 FROM dbo.AR_RECEIVABLES ORDER BY 담당부서")
    depts = [r[0] for r in cursor.fetchall()]

    cursor.execute("SELECT DISTINCT 담당자 FROM dbo.AR_RECEIVABLES ORDER BY 담당자")
    managers = [r[0] for r in cursor.fetchall()]

    conn.close()

    return render_template(
        "index.html",
        columns=columns,
        rows=rows,
        summary=summary,
        statuses=statuses,
        depts=depts,
        managers=managers,
        filters={"status": status, "dept": dept, "manager": manager, "customer": customer, "min_days": min_days},
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=False)
