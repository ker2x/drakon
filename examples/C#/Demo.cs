// Autogenerated with DRAKON Editor 1.11
using System;
using System.Collections.Generic;

namespace Drakon.Editor.Example {

public class Demo {


    public static void Main() {
        // item 52
        Console.WriteLine("DRAKON-C# demo");
        Console.WriteLine("==============");
        // item 189
        foreachDemo();
        // item 50
        quicksortDemo();
    }

    private static List<int> fibonacci(int n) {
        // item 185
        List<int> result = new List<int>();
        // item 186
        result.Add(0);
        // item 1610001
        if (n == 0) {
            
        } else {
            // item 1610002
            if (n == 1) {
                // item 187
                result.Add(1);
            } else {
                // item 188
                result.Add(1);
                // item 1710001
                int i = 2;
                while (true) {
                    // item 1710002
                    if (i <= n) {
                        // item 172
                        int f2 = result[i - 2];
                        int f1 = result[i - 1];
                        int fib = f1 + f2;
                        // item 173
                        result.Add(fib);
                        // item 1710003
                        i++;
                        continue;
                    } else {
                        break;
                    }
                }
            }
        }
        // item 176
        return result;
    }

    private static void foreachDemo() {
        // item 155
        Console.WriteLine("iteration demo");
        // item 153
        List<int> sequence = fibonacci(15);
        // item 154
        printListArrow(sequence);
        printListFor(sequence);
        printListForeach(sequence);
        // item 156
        Console.WriteLine();
    }

    private static void print(Object[] collection) {
        IEnumerator<Object> _it96 = null;
        Object item = default(Object);
        // item 960001
        _it96 = ((IEnumerable<Object>)collection).GetEnumerator();
        while (true) {
            // item 960002
            if (_it96.MoveNext()) {
                // item 960004
                item = _it96.Current;
                // item 98
                write(item);
                continue;
            } else {
                break;
            }
        }
        // item 99
        Console.WriteLine();
    }

    private static void printListArrow(List<int> collection) {
        // item 131
        Console.WriteLine("using if and arrow:");
        // item 126
        int length = collection.Count;
        int i = 0;
        while (true) {
            // item 127
            if (i < length) {
                // item 125
                int item = collection[i];
                write(item);
                // item 129
                i++;
                continue;
            } else {
                break;
            }
        }
        // item 132
        Console.WriteLine("");
    }

    private static void printListFor(List<int> collection) {
        // item 142
        Console.WriteLine("using for:");
        // item 184
        int length = collection.Count;
        // item 1390001
        int i = 0;
        while (true) {
            // item 1390002
            if (i < length) {
                // item 183
                int item = collection[i];
                write(item);
                // item 1390003
                i += 1;
                continue;
            } else {
                break;
            }
        }
        // item 143
        Console.WriteLine("");
    }

    private static void printListForeach(List<int> collection) {
        IEnumerator<int> _it115 = null;
        int item = default(int);
        // item 119
        Console.WriteLine("using foreach:");
        // item 1150001
        _it115 = ((IEnumerable<int>)collection).GetEnumerator();
        while (true) {
            // item 1150002
            if (_it115.MoveNext()) {
                // item 1150004
                item = _it115.Current;
                // item 116
                write(item);
                continue;
            } else {
                break;
            }
        }
        // item 118
        Console.WriteLine("");
    }

    private static void quicksortDemo() {
        // item 62
        Console.WriteLine("quick sort demo");
        // item 58
        Object[] unsorted = new Object[] { "the", "sooner", "we", "start", "this", "the", "better" };
        Object[] sorted   = new Object[] { "aa", "bb", "cc", "dd", "ee", "ff" };
        Object[] reverse  = new Object[] { "ff", "ee", "dd", "cc", "bb", "aa" };
        Object[] empty    = new Object[] {};
        Object[] flat     = new Object[] { "flat", "flat", "flat", "flat", "flat" };
        // item 59
        IComparer<Object> comparer = new ReverseStringComparer();
        Sorter.quicksort(comparer, unsorted, 0, unsorted.Length);
        Sorter.quicksort(comparer, sorted, 0, sorted.Length);
        Sorter.quicksort(comparer, reverse, 0, reverse.Length);
        Sorter.quicksort(comparer, empty, 0, empty.Length);
        Sorter.quicksort(comparer, flat, 0, flat.Length);
        // item 60
        print(unsorted);
        print(sorted);
        print(reverse);
        print(empty);
        print(flat);
        // item 61
        stringsAreSorted(unsorted);
        stringsAreSorted(sorted);
        stringsAreSorted(reverse);
        stringsAreSorted(empty);
        stringsAreSorted(flat);
        // item 65
        Console.WriteLine();
    }

    private static void stringsAreSorted(Object[] array) {
        int _sw810000_ = 0;
        String current = null;
        int i, j = 0;
        int length = array.Length;
        // item 710001
        i = 0;
        int _next_item_ = 0;
        _next_item_ = 710002;
        while (true) {
            if (_next_item_ == 710002) {
                if (i < length) {
                    // item 73
                    current = (String)array[i];
                    // item 740001
                    j = i + 1;
                    _next_item_ = 740002;
                } else {
                    return;
                }
            }
        
            if (_next_item_ == 740002) {
                if (j < length) {
                    // item 76
                    String after = (String)array[j];
                    // item 810000
                    _sw810000_ = current.CompareTo(after);
                    _next_item_ = 810001;
                } else {
                    // item 710003
                    i += 1;
                    _next_item_ = 710002;
                    continue;
                }
            }
        
            if (_next_item_ == 810001) {
                if ((_sw810000_ == 1) || (_sw810000_ == 0)) {
                    // item 740003
                    j += 1;
                    _next_item_ = 740002;
                    continue;
                } else {
                    _next_item_ = 810003;
                }
            }
        
            if (_next_item_ == 810003) {
                if (_sw810000_ == -1) {
                    
                } else {
                    // item 810004
                    throw new InvalidOperationException("Not expected:  " + _sw810000_.ToString());
                }
        
            // item 77
                throw new InvalidOperationException("Collection is not sorted.");
            }
        
        }
    }

    private static void write(Object item) {
        // item 180
        Console.Write(item);
        Console.Write(" ");
    }
}
}