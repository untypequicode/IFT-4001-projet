from .base_exporter import BaseExporter

class LaTeXExporter(BaseExporter):
    def export(self, data, path):
        print(f"Exporting LaTeX to {path}")
