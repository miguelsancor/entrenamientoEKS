from flask import Flask, request, jsonify

app = Flask(__name__)

data_store = []

@app.route('/data', methods=['GET', 'POST'])
def manage_data():
    if request.method == 'POST':
        item = request.json
        data_store.append(item)
        return jsonify({"message": "Item added", "data": item}), 201
    return jsonify(data_store), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
