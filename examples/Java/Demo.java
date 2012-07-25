// Autogenerated with DRAKON Editor 1.11
import java.util.Iterator;
import java.lang.IllegalStateException;
import java.util.List;
import java.util.ArrayList;

public class Demo {

    public static void main(String[] args) {
        // item 52
        System.out.println("DRAKON-Java demo");
        System.out.println("================");
        // item 189
        foreachDemo();
        // item 50
        quicksortDemo();
    }

    private static List<Object> arrayToList(Object[] input) {
        // item 106
        ArrayList<Object> result = new ArrayList<Object>();
        // item 1050001
        int i = 0;
        while (true) {
            // item 1050002
            if (i < input.length) {
                // item 108
                Object item = input[i];
                result.add(item);
                // item 1050003
                i++;
                continue;
            } else {
                break;
            }
        }
        // item 107
        return result;
    }

    private static List<Integer> fibonacci(int n) {
        // item 185
        List<Integer> result = new ArrayList<Integer>();
        // item 186
        result.add(0);
        // item 1610001
        if (n == 0) {
            
        } else {
            // item 1610002
            if (n == 1) {
                // item 187
                result.add(1);
            } else {
                // item 188
                result.add(1);
                // item 1710001
                int i = 2;
                while (true) {
                    // item 1710002
                    if (i <= n) {
                        // item 172
                        Integer f2 = result.get(i - 2);
                        Integer f1 = result.get(i - 1);
                        Integer fib = f1 + f2;
                        // item 173
                        result.add(fib);
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
        System.out.println("iteration demo");
        // item 153
        List<Integer> sequence = fibonacci(15);
        // item 154
        printListArrow(sequence);
        printListFor(sequence);
        printListForeach(sequence);
        // item 156
        System.out.println();
    }

    private static void print(List<Object> collection) {
        Iterator<Object> _it96 = null;
        Object item = null;
        // item 960001
        _it96 = collection.iterator();
        while (true) {
            // item 960002
            if (_it96.hasNext()) {
                // item 960004
                item = _it96.next();
                // item 98
                write(item);
                continue;
            } else {
                break;
            }
        }
        // item 99
        System.out.println();
    }

    private static void printListArrow(List<Integer> collection) {
        // item 131
        System.out.println("using if and arrow:");
        // item 126
        int length = collection.size();
        int i = 0;
        while (true) {
            // item 127
            if (i < length) {
                // item 125
                Integer item = collection.get(i);
                write(item);
                // item 129
                i++;
                continue;
            } else {
                break;
            }
        }
        // item 132
        System.out.println("");
    }

    private static void printListFor(List<Integer> collection) {
        // item 142
        System.out.println("using for:");
        // item 184
        int length = collection.size();
        // item 1390001
        int i = 0;
        while (true) {
            // item 1390002
            if (i < length) {
                // item 183
                Integer item = collection.get(i);
                write(item);
                // item 1390003
                i += 1;
                continue;
            } else {
                break;
            }
        }
        // item 143
        System.out.println("");
    }

    private static void printListForeach(List<Integer> collection) {
        Iterator<Integer> _it115 = null;
        Integer item = null;
        // item 119
        System.out.println("using foreach:");
        // item 1150001
        _it115 = collection.iterator();
        while (true) {
            // item 1150002
            if (_it115.hasNext()) {
                // item 1150004
                item = _it115.next();
                // item 116
                write(item);
                continue;
            } else {
                break;
            }
        }
        // item 118
        System.out.println("");
    }

    private static void quicksortDemo() {
        // item 62
        System.out.println("quick sort demo");
        // item 58
        List<Object> unsorted = arrayToList(new Object[] { "the", "sooner", "we", "start", "this", "the", "better" });
        List<Object> sorted   = arrayToList(new Object[] { "aa", "bb", "cc", "dd", "ee", "ff" });
        List<Object> reverse  = arrayToList(new Object[] { "ff", "ee", "dd", "cc", "bb", "aa" });
        List<Object> empty    = arrayToList(new Object[] {});
        List<Object> flat     = arrayToList(new Object[] { "flat", "flat", "flat", "flat", "flat" });
        // item 59
        Comparer comparer = new ReverseStringComparer();
        Sorter.quicksort(comparer, unsorted, 0, unsorted.size());
        Sorter.quicksort(comparer, sorted, 0, sorted.size());
        Sorter.quicksort(comparer, reverse, 0, reverse.size());
        Sorter.quicksort(comparer, empty, 0, empty.size());
        Sorter.quicksort(comparer, flat, 0, flat.size());
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
        System.out.println();
    }

    private static void stringsAreSorted(List<Object> array) {
        String current = null;
        int i, j = 0;
        int length = array.size();
        int cmpResult = 0;
        // item 710001
        i = 0;
        int _next_item_ = 0;
        _next_item_ = 710002;
        while (true) {
            if (_next_item_ == 710002) {
                if (i < length) {
                    // item 73
                    current = (String)array.get(i);
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
                    String after = (String)array.get(j);
                    // item 190
                    cmpResult = current.compareTo(after);
                    _next_item_ = 191;
                } else {
                    // item 710003
                    i += 1;
                    _next_item_ = 710002;
                    continue;
                }
            }
        
            if (_next_item_ == 191) {
                if (cmpResult < 0) {
                    // item 77
                    throw new IllegalStateException("Collection is not sorted.");
                } else {
                    // item 740003
                    j += 1;
                    _next_item_ = 740002;
                    continue;
                }
            }
        
        }
    }

    private static void write(Object item) {
        // item 180
        System.out.print(item);
        System.out.print(" ");
    }
}
