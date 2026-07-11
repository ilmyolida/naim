import json, urllib.request
url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"
headers = {"Content-Type": "application/json", "X-goog-api-key": "AQ.Ab8RN6Lb45yipZ9DCpZ706G1jj_Tb7YnhzSup1yIuN00I85Vug"}
body = json.dumps({"contents": [{"parts": [{"text": "Explain how AI works in a few words"}]}]}).encode("utf-8")
req = urllib.request.Request(url, data=body, headers=headers, method='POST')
try:
    with urllib.request.urlopen(req, timeout=30) as r:
        print('STATUS', r.status)
        print(r.read().decode('utf-8'))
except Exception as e:
    import traceback
    traceback.print_exc()
