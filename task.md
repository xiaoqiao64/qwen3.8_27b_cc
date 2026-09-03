# 编程任务：实现一个线程安全的 TTL-LRU Cache

请使用 **C++17** 实现一个生产级的内存缓存 `TTLCache`。

## 1. 接口

实现：

```cpp
template <typename K, typename V>
class TTLCache {
public:
    explicit TTLCache(size_t capacity);

    bool get(const K& key, V& value);

    void put(const K& key,
             const V& value,
             std::chrono::milliseconds ttl);

    bool erase(const K& key);

    void clear();

    size_t size() const;

    struct Stats {
        uint64_t hits;
        uint64_t misses;
        uint64_t evictions;
        uint64_t expirations;
    };

    Stats stats() const;
};
```

## 2. LRU 行为

Cache 最大容量为 `capacity`。

例如：

```text
capacity = 3

put(A)
put(B)
put(C)

get(A)

put(D)
```

此时应该淘汰 `B`，因为：

```text
A -> 最近访问
C
B -> 最久未访问
```

要求：

* `get()` 成功后，该元素变成最近使用。
* `put()` 新增元素后，该元素变成最近使用。
* 更新已经存在的 key，也必须将其变成最近使用。
* 当 Cache 超过容量时，淘汰最久未使用的元素。

要求：

```text
get() 平均 O(1)
put() 平均 O(1)
erase() 平均 O(1)
```

---

## 3. TTL

每个元素都有独立的 TTL。

例如：

```cpp
cache.put("A", 100, 1000ms);
```

表示 A 在插入后 1000ms 内有效。

如果：

```text
current_time >= expire_time
```

则该元素已经过期。

要求：

* `get()` 访问已经过期的元素时，必须返回 `false`。
* 访问过期元素时，需要将它从 Cache 中删除。
* 过期元素不能被 `get()` 返回。
* `size()` 返回的数量不能包含已经过期的元素。
* `put()` 时如果发现容量不足，可以优先淘汰已经过期的元素。
* 不要求后台线程主动扫描和删除过期元素。

注意：

不要使用：

```cpp
std::chrono::system_clock
```

实现 TTL。

请说明为什么。

---

## 4. 线程安全

Cache 会被多个线程并发访问。

例如：

```text
Thread 1: get()
Thread 2: put()
Thread 3: erase()
Thread 4: size()
Thread 5: stats()
```

要求：

* 所有 public API 都必须线程安全。
* 不能产生 data race。
* 不能产生 use-after-free。
* 不能返回指向内部容器元素的引用。
* 不要求 lock-free。
* 可以使用 C++ 标准库提供的 mutex / shared_mutex 等同步机制。

请考虑：

```text
get() 修改 LRU 顺序
```

这一点对并发读尤其重要。

---

## 5. Stats

需要统计：

```cpp
hits
misses
evictions
expirations
```

定义：

### hits

`get()` 找到一个仍然有效的元素。

### misses

`get()`：

* key 不存在；
* 或 key 已经过期。

### evictions

由于 Cache 容量限制，主动淘汰一个仍然有效的元素。

### expirations

由于 TTL 过期而删除元素。

例如：

```text
capacity = 2

put(A)
put(B)

get(C)     -> miss

get(A)     -> hit

put(C)
```

如果因为容量限制淘汰 B：

```text
hits        = 1
misses      = 1
evictions   = 1
expirations = 0
```

---

## 6. 特别要求

请特别考虑以下边界条件：

1. `capacity == 0`
2. `ttl == 0`
3. 同一个 key 被重复 `put`
4. `get()` 一个不存在的 key
5. `get()` 一个已经过期的 key
6. `erase()` 一个不存在的 key
7. Cache 满时插入新 key
8. Cache 满但其中存在大量已经过期的 key
9. 多线程同时操作同一个 key
10. 多线程同时更新 LRU 顺序
11. `clear()` 与其他操作并发执行
12. `stats()` 与其他操作并发执行

请明确说明你对这些情况的处理方式。

---

## 7. 数据结构要求

请使用 STL 容器实现。

不得使用：

* 第三方库
* Boost
* 全局变量
* 静态全局 Cache

要求你解释为什么选择这些数据结构。

例如：

```text
std::list
std::unordered_map
```

是否合适？

如果使用其他数据结构，请解释原因。

---

## 8. 测试

除了实现 Cache 之外，请编写测试代码验证：

### 基本 LRU

验证：

```text
A B C
访问 A
插入 D
```

最终淘汰 B。

### TTL

验证：

```text
put(A, ttl=100ms)
立即 get(A) -> success
等待超过 100ms
get(A) -> failure
```

### 更新

验证：

```text
put(A, 1)
put(A, 2)

get(A) == 2
```

### 容量

验证：

```text
capacity = 2

put(A)
put(B)
put(C)

size() == 2
```

### 并发

创建多个线程：

```text
多个线程同时执行 put()
多个线程同时执行 get()
多个线程同时执行 erase()
```

运行一段时间后：

* 程序不能 crash
* 不能产生 data race
* `size() <= capacity`

---

## 9. 最终输出要求

请按照以下顺序回答：

### 第一部分：设计思路

解释：

* 为什么选择这些数据结构？
* 如何保证 O(1) 的 get / put / erase？
* 如何维护 LRU？
* TTL 如何实现？
* 为什么 TTL 应该使用 monotonic clock？
* 如何实现线程安全？
* Stats 如何保证线程安全？
* 是否需要后台线程清理 TTL？为什么？

### 第二部分：完整 C++17 实现

给出可以直接编译运行的完整代码。

### 第三部分：测试代码

给出完整测试代码。

### 第四部分：复杂度分析

分析：

```text
get()
put()
erase()
clear()
size()
stats()
```

的时间复杂度和空间复杂度。

### 第五部分：进一步讨论

回答：

如果这个 Cache 被用于一个高 QPS 服务，例如：

```text
100 个线程
100 万 QPS
Cache capacity = 1,000,000
```

当前设计可能出现什么性能瓶颈？

如何进一步优化？

请不要只给出最终代码，要解释你的设计决策。
