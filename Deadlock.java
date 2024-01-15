package lab7deadlock;
public class Deadlock {
	private final Book book1 = new Book();
    private final Book book2 = new Book();

    public void issueBooks() {
        Thread thread1 = new Thread(() -> {
            synchronized (book1) {
                System.out.println("Thread 1: The Catcher in the Rye");
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                synchronized (book2) {
                    System.out.println("Thread 1: To Kill a Mockingbird");
                }
            }
        });

        Thread thread2 = new Thread(() -> {
            synchronized (book2) {
                System.out.println("Thread 2: To Kill a Mockingbird");
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                synchronized (book1) {
                    System.out.println("Thread 2: The Catcher in the Rye");
                }
            }
        });

        thread1.start();
        thread2.start();
    }

	public static void main(String[] args) {
		Deadlock library = new Deadlock();
        library.issueBooks();
    }
}

class Book {}