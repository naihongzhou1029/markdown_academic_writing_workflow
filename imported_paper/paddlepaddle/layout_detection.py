from paddleocr import LayoutDetection

model = LayoutDetection(model_name="PP-DocLayout-L")
output = model.predict("sample.jpeg", batch_size=1)
for res in output:
    res.print()
    res.save_to_img(save_path="./output/")
    res.save_to_json(save_path="./output/res.json")

