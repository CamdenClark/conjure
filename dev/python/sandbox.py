def add(a, b):
    return a + b

add(4, 29)

4 + 9

5 + \
7 + \
9

"hello"

print("hello world")

a = "foo"
print(a)

a, b = [1, 2]

def print_things_then_return():
    """
    Print things then return!
    """
    for i in range(4):
        print(i)
    return "all done!"

def newline_in_function_bug():
    return "hey" + "\n" + "ho"

print_things_then_return()

for i in range(20):
    print(i)

def fn_with_multiline_str():
    description = """
    This is a super long,
    descriptive, multiline string.
    """
    print(f'Description: {description}')

fn_with_multiline_str()

