import scripts.validation.check_schema as cs

def test_check_schema():
    assert cs.check({}, {}) is True
