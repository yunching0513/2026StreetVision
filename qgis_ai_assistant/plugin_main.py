# -*- coding: utf-8 -*-
"""
QGIS AI Assistant 外掛程式主邏輯。
負責註冊外掛、管理 UI 介面的顯示與隱藏，以及橋接 UI 事件與 AI 處理邏輯。
"""

from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtWidgets import QAction
from qgis.core import Qgis, QgsMessageLog
import traceback

from .ui_dock import AIDockWidget
from .llm_handler import AIWorker

class QGISAIAssistantPlugin:
    """
    QGIS AI Assistant 外掛主類別
    """
    def __init__(self, iface):
        """
        初始化外掛

        :param iface: QGIS 介面實例
        """
        self.iface = iface
        self.plugin_dir = None

        # 宣告動作與 UI 變數
        self.action = None
        self.dock_widget = None
        self.ai_worker = None

    def initGui(self):
        """
        初始化外掛的 GUI 元素，例如將按鈕加入 QGIS 選單或工具列。
        此方法在 QGIS 載入外掛時會自動被呼叫。
        """
        try:
            # 建立一個 QAction 作為開啟工具的選單按鈕
            self.action = QAction("開啟 AI 輔助工具", self.iface.mainWindow())
            # 綁定點擊事件
            self.action.triggered.connect(self.run)

            # 將按鈕加入到 QGIS 的外掛程式選單中 (Plugins menu)
            self.iface.addPluginToMenu("&AI Assistant", self.action)

            QgsMessageLog.logMessage("AI 輔助工具 GUI 初始化成功", "QGIS AI Assistant", Qgis.Info)
        except Exception as e:
            error_msg = f"初始化 GUI 失敗: {str(e)}\n{traceback.format_exc()}"
            QgsMessageLog.logMessage(error_msg, "QGIS AI Assistant", Qgis.Critical)

    def unload(self):
        """
        卸載外掛時的清理工作。
        此方法在 QGIS 關閉外掛時會自動被呼叫。
        """
        try:
            # 從選單移除按鈕
            if self.action:
                self.iface.removePluginMenu("&AI Assistant", self.action)

            # 若 Dock Widget 已經建立，將其從 QGIS 介面中移除並隱藏
            if self.dock_widget:
                self.iface.removeDockWidget(self.dock_widget)
                self.dock_widget.deleteLater()
                self.dock_widget = None

            QgsMessageLog.logMessage("AI 輔助工具已成功卸載", "QGIS AI Assistant", Qgis.Info)
        except Exception as e:
            error_msg = f"卸載外掛失敗: {str(e)}\n{traceback.format_exc()}"
            QgsMessageLog.logMessage(error_msg, "QGIS AI Assistant", Qgis.Critical)

    def run(self):
        """
        當使用者點擊選單按鈕時執行的主要邏輯，負責開啟並顯示 Dock Widget。
        """
        try:
            # 如果 Dock Widget 尚未建立，則初始化它
            if not self.dock_widget:
                self.dock_widget = AIDockWidget(self.iface.mainWindow())

                # 綁定 UI 的送出按鈕事件至處理邏輯
                self.dock_widget.send_button.clicked.connect(self.handle_user_input)
                # 讓輸入框按下 Enter 鍵也能送出
                self.dock_widget.input_field.returnPressed.connect(self.handle_user_input)

                # 將 Dock Widget 加到 QGIS 介面的左側停靠區
                self.iface.addDockWidget(Qt.LeftDockWidgetArea, self.dock_widget)

            # 顯示 Dock Widget
            self.dock_widget.show()

        except Exception as e:
            error_msg = f"啟動 AI 輔助工具失敗: {str(e)}\n{traceback.format_exc()}"
            QgsMessageLog.logMessage(error_msg, "QGIS AI Assistant", Qgis.Critical)

    def handle_user_input(self):
        """
        處理使用者點擊「送出」或按下 Enter 時的邏輯。
        """
        try:
            # 1. 取得並清理使用者輸入的文字
            user_text = self.dock_widget.input_field.text().strip()
            if not user_text:
                return # 如果是空字串，不做任何事

            # 2. 將使用者的訊息顯示在對話歷史中
            self.dock_widget.add_message("使用者", user_text)

            # 3. 清空輸入框，並暫時禁用輸入區，避免重複送出
            self.dock_widget.clear_input()
            self.dock_widget.set_input_enabled(False)

            # 4. 初始化並啟動非同步的 AI 處理執行緒 (Worker)
            self.ai_worker = AIWorker(user_text)

            # 綁定 Worker 的信號與主執行緒的槽 (Slot)
            self.ai_worker.finished.connect(self.on_ai_response)
            self.ai_worker.error.connect(self.on_ai_error)

            # 啟動執行緒
            self.ai_worker.start()

        except Exception as e:
            error_msg = f"處理輸入時發生錯誤: {str(e)}\n{traceback.format_exc()}"
            QgsMessageLog.logMessage(error_msg, "QGIS AI Assistant", Qgis.Critical)
            self.dock_widget.set_input_enabled(True) # 發生錯誤時恢復輸入框狀態

    def on_ai_response(self, response_text):
        """
        當 AIWorker 成功完成任務時，負責將結果顯示在 UI 上。

        :param response_text: AI 的回應文字 (此處為 Mock 結果)
        """
        try:
            # 將 AI 的回應顯示在對話歷史中
            # 將換行符號替換為 HTML 換行，確保在 QTextBrowser 顯示正確
            html_response = response_text.replace('\n', '<br>')
            self.dock_widget.add_message("AI", html_response)

            # 恢復輸入框狀態
            self.dock_widget.set_input_enabled(True)
            self.dock_widget.input_field.setFocus() # 讓輸入框重新獲得焦點

        except Exception as e:
            error_msg = f"處理 AI 回應時發生錯誤: {str(e)}\n{traceback.format_exc()}"
            QgsMessageLog.logMessage(error_msg, "QGIS AI Assistant", Qgis.Critical)

    def on_ai_error(self, error_message):
        """
        當 AIWorker 發生錯誤時，負責處理錯誤訊息。

        :param error_message: 錯誤訊息字串
        """
        try:
            # 在對話介面中顯示系統錯誤訊息
            self.dock_widget.add_message("系統", f"<span style='color:red;'>{error_message}</span>")

            # 將錯誤記錄到 QGIS Message Log
            QgsMessageLog.logMessage(error_message, "QGIS AI Assistant", Qgis.Warning)

            # 恢復輸入框狀態
            self.dock_widget.set_input_enabled(True)
            self.dock_widget.input_field.setFocus()

        except Exception as e:
            QgsMessageLog.logMessage(f"處理 AI 錯誤信號時發生例外: {str(e)}", "QGIS AI Assistant", Qgis.Critical)
