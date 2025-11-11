from scripts.export.exporters.factory import get_exporter

def test_get_exporter():
    assert get_exporter('csv') is not None
