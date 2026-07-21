# -*- coding: utf-8 -*-
"""
UI 介面模組。
負責建立可停靠的側邊面板 (Dock Widget)，包含對話歷史區、輸入框與送出按鈕。
"""

from qgis.PyQt.QtWidgets import (
    QDockWidget,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QTextBrowser,
    QLineEdit,
    QPushButton
)
from qgis.PyQt.QtCore import Qt

class AIDockWidget(QDockWidget):
    """
    AI 輔助工具的 Dock Widget 介面
    """
    def __init__(self, parent=None):
        super(AIDockWidget, self).__init__("AI 輔助工具", parent)
        self.setAllowedAreas(Qt.LeftDockWidgetArea | Qt.RightDockWidgetArea)

        # 初始化 UI 元件
        self.init_ui()

    def init_ui(self):
        """
        設定介面佈局與元件
        """
        # 建立主容器與主要垂直佈局
        self.main_widget = QWidget()
        self.main_layout = QVBoxLayout()

        # 1. 對話歷史顯示區
        self.chat_history = QTextBrowser()
        self.chat_history.setOpenExternalLinks(True) # 允許開啟外部連結
        self.chat_history.setPlaceholderText("歡迎使用 AI 輔助工具！請在下方輸入您的問題。")
        self.main_layout.addWidget(self.chat_history)

        # 2. 輸入區 (水平佈局)
        self.input_layout = QHBoxLayout()

        # 使用者輸入框
        self.input_field = QLineEdit()
        self.input_field.setPlaceholderText("請輸入訊息...")
        self.input_layout.addWidget(self.input_field)

        # 送出按鈕
        self.send_button = QPushButton("送出")
        self.input_layout.addWidget(self.send_button)

        # 將輸入區加入主要佈局
        self.main_layout.addLayout(self.input_layout)

        # 設定主容器的佈局，並將主容器設定為 Dock Widget 的內容
        self.main_widget.setLayout(self.main_layout)
        self.setWidget(self.main_widget)

    def add_message(self, sender, message):
        """
        在對話歷史區新增一筆訊息

        :param sender: 發送者名稱 (例如："使用者" 或 "AI")
        :param message: 訊息內容
        """
        # 使用 HTML 格式讓發送者名稱加粗，方便閱讀
        formatted_msg = f"<b>{sender}:</b> {message}"
        self.chat_history.append(formatted_msg)

    def clear_input(self):
        """
        清空輸入框
        """
        self.input_field.clear()

    def set_input_enabled(self, enabled):
        """
        設定輸入區是否可用 (例如：在 AI 處理中禁用)

        :param enabled: True 代表啟用, False 代表禁用
        """
        self.input_field.setEnabled(enabled)
        self.send_button.setEnabled(enabled)
