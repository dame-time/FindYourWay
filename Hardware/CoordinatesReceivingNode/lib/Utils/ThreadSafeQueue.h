#pragma once

#include <queue>
#include <mutex>

template <typename T>
class ThreadSafeQueue
{
private:
    std::queue<T> queue;
    std::mutex mutex;

public:
    void push(const T &value)
    {
        std::lock_guard<std::mutex> lock(mutex);
        queue.push(value);
    }

    bool canPop()
    {
        return !queue.empty();
    }

    T pop()
    {
        std::lock_guard<std::mutex> lock(mutex);

        T value = queue.front();
        queue.pop();

        return value;
    }
};
