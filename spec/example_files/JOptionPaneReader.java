import javax.swing.JOptionPane;

public class JOptionPaneReader {
  public static void main(String[] args) {
    for (int i = 0; i < 3; i++) {
      String input = JOptionPane.showInputDialog("Give me input!");
      JOptionPane.showMessageDialog(null, input);
    }
  }
}
