# -*- coding: utf-8 -*-
"""
AI 處理模組與 QGIS 狀態讀取。
包含一個非同步的 Worker (QThread)，負責處理使用者訊息並回傳 Mock 的 AI 回應。
同時實作了讀取 QGIS 當前載入的所有圖層名稱與類型的功能。
"""

import time
from qgis.PyQt.QtCore import QThread, pyqtSignal
from qgis.core import QgsProject, QgsMapLayer

def get_qgis_layer_info():
    """
    讀取目前 QGIS 專案中所有載入的圖層名稱與類型。

    :return: 包含所有圖層名稱與類型的字串，若無圖層則回傳提示訊息。
    """
    layers = QgsProject.instance().mapLayers().values()

    if not layers:
        return "目前沒有載入任何圖層。"

    layer_info_list = []
    for layer in layers:
        # 取得圖層名稱
        layer_name = layer.name()

        # 取得圖層類型 (例如：Vector, Raster 等)
        # 注意：QGIS 3.x 使用 QgsMapLayerType (或在新版中用 Qgis.LayerType)
        from qgis.core import QgsMapLayerType
        layer_type = "未知"
        if layer.type() == QgsMapLayerType.VectorLayer:
            layer_type = "向量 (Vector)"
        elif layer.type() == QgsMapLayerType.RasterLayer:
            layer_type = "網格 (Raster)"
        elif layer.type() == QgsMapLayerType.MeshLayer:
            layer_type = "網格 (Mesh)"
        elif layer.type() == QgsMapLayerType.PluginLayer:
            layer_type = "外掛 (Plugin)"

        layer_info_list.append(f"- {layer_name} ({layer_type})")

    return "目前載入的圖層有：\n" + "\n".join(layer_info_list)

class AIWorker(QThread):
    """
    負責與 AI 互動的非同步執行緒 (Mock 版本)。
    確保處理 AI 請求時不會阻塞 QGIS 的主介面。
    """
    # 定義自訂信號：當處理完成時發射，傳遞 AI 回應字串
    finished = pyqtSignal(str)
    # 定義自訂信號：當發生錯誤時發射，傳遞錯誤訊息字串
    error = pyqtSignal(str)

    def __init__(self, user_message, parent=None):
        """
        初始化 Worker

        :param user_message: 使用者輸入的文字訊息
        """
        super(AIWorker, self).__init__(parent)
        self.user_message = user_message

    def run(self):
        """
        執行緒的主要任務內容
        """
        try:
            # 1. 模擬網路延遲與 API 呼叫 (延遲 1 秒)
            time.sleep(1.0)

            # 2. 取得目前 QGIS 的圖層狀態
            # 注意：大部分 QGIS Core API 可以安全地在背景執行緒中「讀取」狀態。
            # 但若要「修改」地圖內容或 UI，必須透過信號 (Signal) 交給主執行緒處理。
            layer_context = get_qgis_layer_info()

            # 3. 組合 Mock 回應
            ai_response = f"這是一段 AI 測試回應。您剛剛說了：「{self.user_message}」\n\n【目前的 QGIS 狀態】\n{layer_context}"

            # 4. 發射完成信號，將結果傳回主執行緒
            self.finished.emit(ai_response)

        except Exception as e:
            # 若發生錯誤，發射錯誤信號
            self.error.emit(f"AI 處理過程中發生錯誤: {str(e)}")
