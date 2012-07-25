/* Autogenerated with DRAKON Editor 1.11 */
#ifndef QT_CPP_H75472
#define QT_CPP_H75472

#include <QtCore/QObject>

int main();

class QtDemo: public QObject {

	Q_OBJECT


private:
    // non-copyable
    QtDemo(const QtDemo& other) {}
    void operator=(const QtDemo& other) {}
public:
    explicit QtDemo();

signals:
    void MySignal(
        int i
    );

public slots:
    virtual void SlotA(
        int i
    );

protected slots:
    void SlotB(
        int i
    );

private slots:
    void SlotC(
        int i
    );

public:
    void DoIt();

};

#endif
