import argparse
import json
from typing import Optional
import urllib.request


def post_json(url: str, body: Optional[dict] = None) -> dict:
    data = None
    headers = {}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=data, headers=headers, method="POST")
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run MVP bootstrap and sample question generation")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000", help="API base URL")
    parser.add_argument("--count", type=int, default=5, help="Question count")
    args = parser.parse_args()

    bootstrap = post_json(f"{args.base_url}/mvp/bootstrap?clear_existing=true")
    print("Bootstrap:")
    print(json.dumps(bootstrap, ensure_ascii=False, indent=2))

    questions = post_json(
        f"{args.base_url}/questions/generate",
        body={"count": args.count, "target_type": "player"},
    )

    print("\nGenerated questions:")
    print(json.dumps(questions, ensure_ascii=False, indent=2))
