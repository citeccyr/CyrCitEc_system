

def sheet(fufi):
    string = ''
    with open(fufi, 'r') as file:
        string = file.read()
        sheet = etree.XSLT(etree.parse(fufi))
