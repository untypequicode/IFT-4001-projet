from .base_exporter import BaseExporter

class HTMLExporter(BaseExporter):
    def export(self, data, path):
        print(f"Exporting HTML to {path}")
