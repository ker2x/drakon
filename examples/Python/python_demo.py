#!/usr/bin/env python

import sys

# Autogenerated with DRAKON Editor 1.11

def fibonacci(n):
    #item 1530001
    if n == 0:
        #item 157
        result = [0]
    else:
        #item 1530002
        if n == 1:
            #item 158
            result = [0, 1]
        else:
            #item 159
            result = [0, 1]
            #item 1630001
            i = 2
            while True:
                #item 1630002
                if i <= n:
                    #item 164
                    f2 = result[i - 2]
                    f1 = result[i - 1]
                    fib = f1 + f2
                    #item 165
                    result.append(fib)
                    #item 1630003
                    i += 1
                    continue
                else:
                    break
    #item 168
    return result


def foreach_demo():
    #item 178
    print("iteration demo")
    #item 169
    sequence = fibonacci(15)
    #item 170
    print_list_arrow(sequence)
    print_list_for(sequence)
    print_list_foreach(sequence)
    #item 179
    print("")


def main():
    #item 182
    print("DRAKON-Python demo")
    print("==================")
    #item 174
    foreach_demo()
    #item 175
    quick_sort_demo()


def print_list_arrow(collection):
    #item 134
    print("using if and arrow:")
    #item 120
    length = len(collection)
    i = 0
    while True:
        #item 121
        if i < length:
            #item 119
            item = collection[i]
            write(item)
            #item 123
            i += 1
            continue
        else:
            break
    #item 135
    print("")


def print_list_for(collection):
    #item 176
    print("using for:")
    #item 130
    length = len(collection)
    #item 1310001
    i = 0
    while True:
        #item 1310002
        if i < length:
            #item 133
            item = collection[i]
            write(item)
            #item 1310003
            i += 1
            continue
        else:
            break
    #item 177
    print("")


def print_list_foreach(collection):
    #item 137
    print("using foreach:")
    #item 1110001
    _it111 = iter(collection)
    try:
        item = _it111.next()
        _go111 = True
    except StopIteration:
        _go111 = False
    while True:
        #item 1110002
        if _go111:
            #item 112
            write(item)
            #item 1110003
            try:
                item = _it111.next()
                _go111 = True
            except StopIteration:
                _go111 = False
            continue
        else:
            break
    #item 136
    print("")


def quick_sort_demo():
    #item 181
    print("quick sort demo")
    #item 17
    unsorted = [ "the", "sooner", "we", "start", "this", "the", "better" ]
    sorted = [ "aa", "bb", "cc", "dd", "ee", "ff" ]
    reverse = [ "ff", "ee", "dd", "cc", "bb", "aa" ]
    empty = []
    flat = [ "flat", "flat", "flat", "flat", "flat" ]
    #item 18
    sorter = Sorter(string_comparer)
    unsorted2 = sorter.quick_sort(unsorted)
    sorted2 = sorter.quick_sort(sorted)
    reverse2 = sorter.quick_sort(reverse)
    empty2 = sorter.quick_sort(empty)
    flat2 = sorter.quick_sort(flat)
    #item 19
    print(str(unsorted2))
    print(str(sorted2))
    print(str(reverse2))
    print(str(empty2))
    print(str(flat2))
    #item 20
    strings_are_sorted(unsorted2)
    strings_are_sorted(sorted2)
    strings_are_sorted(reverse2)
    strings_are_sorted(empty2)
    strings_are_sorted(flat2)
    #item 180
    print("")


def string_comparer(left, right):
    #item 6
    if left < right:
        #item 7
        return -1
    else:
        #item 10
        if left > right:
            #item 9
            return 1
        else:
            #item 8
            return 0


def strings_are_sorted(array):
    length = len(array)
    #item 260001
    i = 0
    
    _next_item_ = 260002
    while True:
        if _next_item_ == 260002:
            if i < length:
                #item 28
                current = array[i]
                #item 290001
                j = i + 1
                _next_item_ = 290002
            else:
                return None
    
        if _next_item_ == 290002:
            if j < length:
                #item 31
                after = array[j]
                #item 360000
                _sw360000_ = string_comparer(current, after)
                _next_item_ = 360001
            else:
                #item 260003
                i += 1
                _next_item_ = 260002
                continue
    
        if _next_item_ == 360001:
            if (_sw360000_ == -1) or (_sw360000_ == 0):
                #item 290003
                j += 1
                _next_item_ = 290002
                continue
            else:
                _next_item_ = 360003
    
        if _next_item_ == 360003:
            if _sw360000_ == 1:
                pass
            else:
                #item 360004
                raise Exception("Not expected:  " + str(_sw360000_))
    
        #item 32
            raise Exception( "Collection is not sorted:\n" + str(array))
            return None
    


def write(item):
    #item 142
    sys.stdout.write(str(item))
    sys.stdout.write(" ")

class Sorter:
    foo = ""


    def __init__(self, comparer):
        #item 105
        self.comparer = comparer


    def quick_sort(self, collection):
        #item 60
        length = len(collection)
        #item 610001
        if (length == 0) or (length == 1):
            #item 72
            result = collection
        else:
            #item 610003
            if length == 2:
                #item 77
                first = collection[0]
                second = collection[1]
                #item 78
                if self.comparer(first, second) < 0:
                    #item 98
                    result = collection
                else:
                    #item 79
                    result = [ second, first ]
            else:
                #item 82
                half = int(length / 2)
                median = collection[half]
                left = []
                right = []
                #item 830001
                i = 0
                while True:
                    #item 830002
                    if i < length:
                        #item 96
                        if i == half:
                            pass
                        else:
                            #item 85
                            current = collection[i]
                            #item 86
                            if self.comparer(current, median) < 0:
                                #item 87
                                left.append(current)
                            else:
                                #item 88
                                right.append(current)
                        #item 830003
                        i += 1
                        continue
                    else:
                        break
                #item 94
                left_sorted = self.quick_sort(left)
                right_sorted = self.quick_sort(right)
                #item 95
                result = []
                result.extend(left_sorted)
                result.append(median)
                result.extend(right_sorted)
        #item 99
        return result

main()
