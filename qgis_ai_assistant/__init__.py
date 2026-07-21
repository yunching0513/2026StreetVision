# -*- coding: utf-8 -*-
"""
初始化 QGIS 外掛程式。
QGIS 會在載入外掛時執行此檔案中的 classFactory 函數。
"""

def classFactory(iface):
    """
    QGIS 載入外掛時的進入點。

    :param iface: QGIS 主介面實例 (QgisInterface)，供外掛與 QGIS 介面互動
    :return: 實例化後的外掛主類別
    """
    from .plugin_main import QGISAIAssistantPlugin
    return QGISAIAssistantPlugin(iface)
