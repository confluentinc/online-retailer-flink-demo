/**
 * Autogenerated by Avro
 *
 * DO NOT EDIT DIRECTLY
 */
package io.confluent.examples.datacontract.pojo.avro;

import org.apache.avro.generic.GenericArray;
import org.apache.avro.specific.SpecificData;
import org.apache.avro.util.Utf8;
import org.apache.avro.message.BinaryMessageEncoder;
import org.apache.avro.message.BinaryMessageDecoder;
import org.apache.avro.message.SchemaStore;

@org.apache.avro.specific.AvroGenerated
public class Sale extends org.apache.avro.specific.SpecificRecordBase implements org.apache.avro.specific.SpecificRecord {
  private static final long serialVersionUID = 7028236685207719807L;


  public static final org.apache.avro.Schema SCHEMA$ = new org.apache.avro.Schema.Parser().parse("{\"type\":\"record\",\"name\":\"Sale\",\"namespace\":\"io.confluent.examples.datacontract.pojo.avro\",\"fields\":[{\"name\":\"order_id\",\"type\":\"int\"},{\"name\":\"product_id\",\"type\":\"int\"},{\"name\":\"customer_id\",\"type\":\"int\"},{\"name\":\"confirmation_code\",\"type\":\"string\"},{\"name\":\"cc_number\",\"type\":\"string\"},{\"name\":\"expiration\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"ts\",\"type\":{\"type\":\"long\",\"logicalType\":\"timestamp-millis\"}}]}");
  public static org.apache.avro.Schema getClassSchema() { return SCHEMA$; }

  private static final SpecificData MODEL$ = new SpecificData();
  static {
    MODEL$.addLogicalTypeConversion(new org.apache.avro.data.TimeConversions.TimestampMillisConversion());
  }

  private static final BinaryMessageEncoder<Sale> ENCODER =
      new BinaryMessageEncoder<>(MODEL$, SCHEMA$);

  private static final BinaryMessageDecoder<Sale> DECODER =
      new BinaryMessageDecoder<>(MODEL$, SCHEMA$);

  /**
   * Return the BinaryMessageEncoder instance used by this class.
   * @return the message encoder used by this class
   */
  public static BinaryMessageEncoder<Sale> getEncoder() {
    return ENCODER;
  }

  /**
   * Return the BinaryMessageDecoder instance used by this class.
   * @return the message decoder used by this class
   */
  public static BinaryMessageDecoder<Sale> getDecoder() {
    return DECODER;
  }

  /**
   * Create a new BinaryMessageDecoder instance for this class that uses the specified {@link SchemaStore}.
   * @param resolver a {@link SchemaStore} used to find schemas by fingerprint
   * @return a BinaryMessageDecoder instance for this class backed by the given SchemaStore
   */
  public static BinaryMessageDecoder<Sale> createDecoder(SchemaStore resolver) {
    return new BinaryMessageDecoder<>(MODEL$, SCHEMA$, resolver);
  }

  /**
   * Serializes this Sale to a ByteBuffer.
   * @return a buffer holding the serialized data for this instance
   * @throws java.io.IOException if this instance could not be serialized
   */
  public java.nio.ByteBuffer toByteBuffer() throws java.io.IOException {
    return ENCODER.encode(this);
  }

  /**
   * Deserializes a Sale from a ByteBuffer.
   * @param b a byte buffer holding serialized data for an instance of this class
   * @return a Sale instance decoded from the given buffer
   * @throws java.io.IOException if the given bytes could not be deserialized into an instance of this class
   */
  public static Sale fromByteBuffer(
      java.nio.ByteBuffer b) throws java.io.IOException {
    return DECODER.decode(b);
  }

  private int order_id;
  private int product_id;
  private int customer_id;
  private java.lang.CharSequence confirmation_code;
  private java.lang.CharSequence cc_number;
  private java.lang.CharSequence expiration;
  private double amount;
  private java.time.Instant ts;

  /**
   * Default constructor.  Note that this does not initialize fields
   * to their default values from the schema.  If that is desired then
   * one should use <code>newBuilder()</code>.
   */
  public Sale() {}

  /**
   * All-args constructor.
   * @param order_id The new value for order_id
   * @param product_id The new value for product_id
   * @param customer_id The new value for customer_id
   * @param confirmation_code The new value for confirmation_code
   * @param cc_number The new value for cc_number
   * @param expiration The new value for expiration
   * @param amount The new value for amount
   * @param ts The new value for ts
   */
  public Sale(java.lang.Integer order_id, java.lang.Integer product_id, java.lang.Integer customer_id, java.lang.CharSequence confirmation_code, java.lang.CharSequence cc_number, java.lang.CharSequence expiration, java.lang.Double amount, java.time.Instant ts) {
    this.order_id = order_id;
    this.product_id = product_id;
    this.customer_id = customer_id;
    this.confirmation_code = confirmation_code;
    this.cc_number = cc_number;
    this.expiration = expiration;
    this.amount = amount;
    this.ts = ts.truncatedTo(java.time.temporal.ChronoUnit.MILLIS);
  }

  @Override
  public org.apache.avro.specific.SpecificData getSpecificData() { return MODEL$; }

  @Override
  public org.apache.avro.Schema getSchema() { return SCHEMA$; }

  // Used by DatumWriter.  Applications should not call.
  @Override
  public java.lang.Object get(int field$) {
    switch (field$) {
    case 0: return order_id;
    case 1: return product_id;
    case 2: return customer_id;
    case 3: return confirmation_code;
    case 4: return cc_number;
    case 5: return expiration;
    case 6: return amount;
    case 7: return ts;
    default: throw new IndexOutOfBoundsException("Invalid index: " + field$);
    }
  }

  private static final org.apache.avro.Conversion<?>[] conversions =
      new org.apache.avro.Conversion<?>[] {
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      new org.apache.avro.data.TimeConversions.TimestampMillisConversion(),
      null
  };

  @Override
  public org.apache.avro.Conversion<?> getConversion(int field) {
    return conversions[field];
  }

  // Used by DatumReader.  Applications should not call.
  @Override
  @SuppressWarnings(value="unchecked")
  public void put(int field$, java.lang.Object value$) {
    switch (field$) {
    case 0: order_id = (java.lang.Integer)value$; break;
    case 1: product_id = (java.lang.Integer)value$; break;
    case 2: customer_id = (java.lang.Integer)value$; break;
    case 3: confirmation_code = (java.lang.CharSequence)value$; break;
    case 4: cc_number = (java.lang.CharSequence)value$; break;
    case 5: expiration = (java.lang.CharSequence)value$; break;
    case 6: amount = (java.lang.Double)value$; break;
    case 7: ts = (java.time.Instant)value$; break;
    default: throw new IndexOutOfBoundsException("Invalid index: " + field$);
    }
  }

  /**
   * Gets the value of the 'order_id' field.
   * @return The value of the 'order_id' field.
   */
  public int getOrderId() {
    return order_id;
  }


  /**
   * Sets the value of the 'order_id' field.
   * @param value the value to set.
   */
  public void setOrderId(int value) {
    this.order_id = value;
  }

  /**
   * Gets the value of the 'product_id' field.
   * @return The value of the 'product_id' field.
   */
  public int getProductId() {
    return product_id;
  }


  /**
   * Sets the value of the 'product_id' field.
   * @param value the value to set.
   */
  public void setProductId(int value) {
    this.product_id = value;
  }

  /**
   * Gets the value of the 'customer_id' field.
   * @return The value of the 'customer_id' field.
   */
  public int getCustomerId() {
    return customer_id;
  }


  /**
   * Sets the value of the 'customer_id' field.
   * @param value the value to set.
   */
  public void setCustomerId(int value) {
    this.customer_id = value;
  }

  /**
   * Gets the value of the 'confirmation_code' field.
   * @return The value of the 'confirmation_code' field.
   */
  public java.lang.CharSequence getConfirmationCode() {
    return confirmation_code;
  }


  /**
   * Sets the value of the 'confirmation_code' field.
   * @param value the value to set.
   */
  public void setConfirmationCode(java.lang.CharSequence value) {
    this.confirmation_code = value;
  }

  /**
   * Gets the value of the 'cc_number' field.
   * @return The value of the 'cc_number' field.
   */
  public java.lang.CharSequence getCcNumber() {
    return cc_number;
  }


  /**
   * Sets the value of the 'cc_number' field.
   * @param value the value to set.
   */
  public void setCcNumber(java.lang.CharSequence value) {
    this.cc_number = value;
  }

  /**
   * Gets the value of the 'expiration' field.
   * @return The value of the 'expiration' field.
   */
  public java.lang.CharSequence getExpiration() {
    return expiration;
  }


  /**
   * Sets the value of the 'expiration' field.
   * @param value the value to set.
   */
  public void setExpiration(java.lang.CharSequence value) {
    this.expiration = value;
  }

  /**
   * Gets the value of the 'amount' field.
   * @return The value of the 'amount' field.
   */
  public double getAmount() {
    return amount;
  }


  /**
   * Sets the value of the 'amount' field.
   * @param value the value to set.
   */
  public void setAmount(double value) {
    this.amount = value;
  }

  /**
   * Gets the value of the 'ts' field.
   * @return The value of the 'ts' field.
   */
  public java.time.Instant getTs() {
    return ts;
  }


  /**
   * Sets the value of the 'ts' field.
   * @param value the value to set.
   */
  public void setTs(java.time.Instant value) {
    this.ts = value.truncatedTo(java.time.temporal.ChronoUnit.MILLIS);
  }

  /**
   * Creates a new Sale RecordBuilder.
   * @return A new Sale RecordBuilder
   */
  public static io.confluent.examples.datacontract.pojo.avro.Sale.Builder newBuilder() {
    return new io.confluent.examples.datacontract.pojo.avro.Sale.Builder();
  }

  /**
   * Creates a new Sale RecordBuilder by copying an existing Builder.
   * @param other The existing builder to copy.
   * @return A new Sale RecordBuilder
   */
  public static io.confluent.examples.datacontract.pojo.avro.Sale.Builder newBuilder(io.confluent.examples.datacontract.pojo.avro.Sale.Builder other) {
    if (other == null) {
      return new io.confluent.examples.datacontract.pojo.avro.Sale.Builder();
    } else {
      return new io.confluent.examples.datacontract.pojo.avro.Sale.Builder(other);
    }
  }

  /**
   * Creates a new Sale RecordBuilder by copying an existing Sale instance.
   * @param other The existing instance to copy.
   * @return A new Sale RecordBuilder
   */
  public static io.confluent.examples.datacontract.pojo.avro.Sale.Builder newBuilder(io.confluent.examples.datacontract.pojo.avro.Sale other) {
    if (other == null) {
      return new io.confluent.examples.datacontract.pojo.avro.Sale.Builder();
    } else {
      return new io.confluent.examples.datacontract.pojo.avro.Sale.Builder(other);
    }
  }

  /**
   * RecordBuilder for Sale instances.
   */
  @org.apache.avro.specific.AvroGenerated
  public static class Builder extends org.apache.avro.specific.SpecificRecordBuilderBase<Sale>
    implements org.apache.avro.data.RecordBuilder<Sale> {

    private int order_id;
    private int product_id;
    private int customer_id;
    private java.lang.CharSequence confirmation_code;
    private java.lang.CharSequence cc_number;
    private java.lang.CharSequence expiration;
    private double amount;
    private java.time.Instant ts;

    /** Creates a new Builder */
    private Builder() {
      super(SCHEMA$, MODEL$);
    }

    /**
     * Creates a Builder by copying an existing Builder.
     * @param other The existing Builder to copy.
     */
    private Builder(io.confluent.examples.datacontract.pojo.avro.Sale.Builder other) {
      super(other);
      if (isValidValue(fields()[0], other.order_id)) {
        this.order_id = data().deepCopy(fields()[0].schema(), other.order_id);
        fieldSetFlags()[0] = other.fieldSetFlags()[0];
      }
      if (isValidValue(fields()[1], other.product_id)) {
        this.product_id = data().deepCopy(fields()[1].schema(), other.product_id);
        fieldSetFlags()[1] = other.fieldSetFlags()[1];
      }
      if (isValidValue(fields()[2], other.customer_id)) {
        this.customer_id = data().deepCopy(fields()[2].schema(), other.customer_id);
        fieldSetFlags()[2] = other.fieldSetFlags()[2];
      }
      if (isValidValue(fields()[3], other.confirmation_code)) {
        this.confirmation_code = data().deepCopy(fields()[3].schema(), other.confirmation_code);
        fieldSetFlags()[3] = other.fieldSetFlags()[3];
      }
      if (isValidValue(fields()[4], other.cc_number)) {
        this.cc_number = data().deepCopy(fields()[4].schema(), other.cc_number);
        fieldSetFlags()[4] = other.fieldSetFlags()[4];
      }
      if (isValidValue(fields()[5], other.expiration)) {
        this.expiration = data().deepCopy(fields()[5].schema(), other.expiration);
        fieldSetFlags()[5] = other.fieldSetFlags()[5];
      }
      if (isValidValue(fields()[6], other.amount)) {
        this.amount = data().deepCopy(fields()[6].schema(), other.amount);
        fieldSetFlags()[6] = other.fieldSetFlags()[6];
      }
      if (isValidValue(fields()[7], other.ts)) {
        this.ts = data().deepCopy(fields()[7].schema(), other.ts);
        fieldSetFlags()[7] = other.fieldSetFlags()[7];
      }
    }

    /**
     * Creates a Builder by copying an existing Sale instance
     * @param other The existing instance to copy.
     */
    private Builder(io.confluent.examples.datacontract.pojo.avro.Sale other) {
      super(SCHEMA$, MODEL$);
      if (isValidValue(fields()[0], other.order_id)) {
        this.order_id = data().deepCopy(fields()[0].schema(), other.order_id);
        fieldSetFlags()[0] = true;
      }
      if (isValidValue(fields()[1], other.product_id)) {
        this.product_id = data().deepCopy(fields()[1].schema(), other.product_id);
        fieldSetFlags()[1] = true;
      }
      if (isValidValue(fields()[2], other.customer_id)) {
        this.customer_id = data().deepCopy(fields()[2].schema(), other.customer_id);
        fieldSetFlags()[2] = true;
      }
      if (isValidValue(fields()[3], other.confirmation_code)) {
        this.confirmation_code = data().deepCopy(fields()[3].schema(), other.confirmation_code);
        fieldSetFlags()[3] = true;
      }
      if (isValidValue(fields()[4], other.cc_number)) {
        this.cc_number = data().deepCopy(fields()[4].schema(), other.cc_number);
        fieldSetFlags()[4] = true;
      }
      if (isValidValue(fields()[5], other.expiration)) {
        this.expiration = data().deepCopy(fields()[5].schema(), other.expiration);
        fieldSetFlags()[5] = true;
      }
      if (isValidValue(fields()[6], other.amount)) {
        this.amount = data().deepCopy(fields()[6].schema(), other.amount);
        fieldSetFlags()[6] = true;
      }
      if (isValidValue(fields()[7], other.ts)) {
        this.ts = data().deepCopy(fields()[7].schema(), other.ts);
        fieldSetFlags()[7] = true;
      }
    }

    /**
      * Gets the value of the 'order_id' field.
      * @return The value.
      */
    public int getOrderId() {
      return order_id;
    }


    /**
      * Sets the value of the 'order_id' field.
      * @param value The value of 'order_id'.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder setOrderId(int value) {
      validate(fields()[0], value);
      this.order_id = value;
      fieldSetFlags()[0] = true;
      return this;
    }

    /**
      * Checks whether the 'order_id' field has been set.
      * @return True if the 'order_id' field has been set, false otherwise.
      */
    public boolean hasOrderId() {
      return fieldSetFlags()[0];
    }


    /**
      * Clears the value of the 'order_id' field.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder clearOrderId() {
      fieldSetFlags()[0] = false;
      return this;
    }

    /**
      * Gets the value of the 'product_id' field.
      * @return The value.
      */
    public int getProductId() {
      return product_id;
    }


    /**
      * Sets the value of the 'product_id' field.
      * @param value The value of 'product_id'.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder setProductId(int value) {
      validate(fields()[1], value);
      this.product_id = value;
      fieldSetFlags()[1] = true;
      return this;
    }

    /**
      * Checks whether the 'product_id' field has been set.
      * @return True if the 'product_id' field has been set, false otherwise.
      */
    public boolean hasProductId() {
      return fieldSetFlags()[1];
    }


    /**
      * Clears the value of the 'product_id' field.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder clearProductId() {
      fieldSetFlags()[1] = false;
      return this;
    }

    /**
      * Gets the value of the 'customer_id' field.
      * @return The value.
      */
    public int getCustomerId() {
      return customer_id;
    }


    /**
      * Sets the value of the 'customer_id' field.
      * @param value The value of 'customer_id'.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder setCustomerId(int value) {
      validate(fields()[2], value);
      this.customer_id = value;
      fieldSetFlags()[2] = true;
      return this;
    }

    /**
      * Checks whether the 'customer_id' field has been set.
      * @return True if the 'customer_id' field has been set, false otherwise.
      */
    public boolean hasCustomerId() {
      return fieldSetFlags()[2];
    }


    /**
      * Clears the value of the 'customer_id' field.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder clearCustomerId() {
      fieldSetFlags()[2] = false;
      return this;
    }

    /**
      * Gets the value of the 'confirmation_code' field.
      * @return The value.
      */
    public java.lang.CharSequence getConfirmationCode() {
      return confirmation_code;
    }


    /**
      * Sets the value of the 'confirmation_code' field.
      * @param value The value of 'confirmation_code'.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder setConfirmationCode(java.lang.CharSequence value) {
      validate(fields()[3], value);
      this.confirmation_code = value;
      fieldSetFlags()[3] = true;
      return this;
    }

    /**
      * Checks whether the 'confirmation_code' field has been set.
      * @return True if the 'confirmation_code' field has been set, false otherwise.
      */
    public boolean hasConfirmationCode() {
      return fieldSetFlags()[3];
    }


    /**
      * Clears the value of the 'confirmation_code' field.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder clearConfirmationCode() {
      confirmation_code = null;
      fieldSetFlags()[3] = false;
      return this;
    }

    /**
      * Gets the value of the 'cc_number' field.
      * @return The value.
      */
    public java.lang.CharSequence getCcNumber() {
      return cc_number;
    }


    /**
      * Sets the value of the 'cc_number' field.
      * @param value The value of 'cc_number'.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder setCcNumber(java.lang.CharSequence value) {
      validate(fields()[4], value);
      this.cc_number = value;
      fieldSetFlags()[4] = true;
      return this;
    }

    /**
      * Checks whether the 'cc_number' field has been set.
      * @return True if the 'cc_number' field has been set, false otherwise.
      */
    public boolean hasCcNumber() {
      return fieldSetFlags()[4];
    }


    /**
      * Clears the value of the 'cc_number' field.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder clearCcNumber() {
      cc_number = null;
      fieldSetFlags()[4] = false;
      return this;
    }

    /**
      * Gets the value of the 'expiration' field.
      * @return The value.
      */
    public java.lang.CharSequence getExpiration() {
      return expiration;
    }


    /**
      * Sets the value of the 'expiration' field.
      * @param value The value of 'expiration'.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder setExpiration(java.lang.CharSequence value) {
      validate(fields()[5], value);
      this.expiration = value;
      fieldSetFlags()[5] = true;
      return this;
    }

    /**
      * Checks whether the 'expiration' field has been set.
      * @return True if the 'expiration' field has been set, false otherwise.
      */
    public boolean hasExpiration() {
      return fieldSetFlags()[5];
    }


    /**
      * Clears the value of the 'expiration' field.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder clearExpiration() {
      expiration = null;
      fieldSetFlags()[5] = false;
      return this;
    }

    /**
      * Gets the value of the 'amount' field.
      * @return The value.
      */
    public double getAmount() {
      return amount;
    }


    /**
      * Sets the value of the 'amount' field.
      * @param value The value of 'amount'.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder setAmount(double value) {
      validate(fields()[6], value);
      this.amount = value;
      fieldSetFlags()[6] = true;
      return this;
    }

    /**
      * Checks whether the 'amount' field has been set.
      * @return True if the 'amount' field has been set, false otherwise.
      */
    public boolean hasAmount() {
      return fieldSetFlags()[6];
    }


    /**
      * Clears the value of the 'amount' field.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder clearAmount() {
      fieldSetFlags()[6] = false;
      return this;
    }

    /**
      * Gets the value of the 'ts' field.
      * @return The value.
      */
    public java.time.Instant getTs() {
      return ts;
    }


    /**
      * Sets the value of the 'ts' field.
      * @param value The value of 'ts'.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder setTs(java.time.Instant value) {
      validate(fields()[7], value);
      this.ts = value.truncatedTo(java.time.temporal.ChronoUnit.MILLIS);
      fieldSetFlags()[7] = true;
      return this;
    }

    /**
      * Checks whether the 'ts' field has been set.
      * @return True if the 'ts' field has been set, false otherwise.
      */
    public boolean hasTs() {
      return fieldSetFlags()[7];
    }


    /**
      * Clears the value of the 'ts' field.
      * @return This builder.
      */
    public io.confluent.examples.datacontract.pojo.avro.Sale.Builder clearTs() {
      fieldSetFlags()[7] = false;
      return this;
    }

    @Override
    @SuppressWarnings("unchecked")
    public Sale build() {
      try {
        Sale record = new Sale();
        record.order_id = fieldSetFlags()[0] ? this.order_id : (java.lang.Integer) defaultValue(fields()[0]);
        record.product_id = fieldSetFlags()[1] ? this.product_id : (java.lang.Integer) defaultValue(fields()[1]);
        record.customer_id = fieldSetFlags()[2] ? this.customer_id : (java.lang.Integer) defaultValue(fields()[2]);
        record.confirmation_code = fieldSetFlags()[3] ? this.confirmation_code : (java.lang.CharSequence) defaultValue(fields()[3]);
        record.cc_number = fieldSetFlags()[4] ? this.cc_number : (java.lang.CharSequence) defaultValue(fields()[4]);
        record.expiration = fieldSetFlags()[5] ? this.expiration : (java.lang.CharSequence) defaultValue(fields()[5]);
        record.amount = fieldSetFlags()[6] ? this.amount : (java.lang.Double) defaultValue(fields()[6]);
        record.ts = fieldSetFlags()[7] ? this.ts : (java.time.Instant) defaultValue(fields()[7]);
        return record;
      } catch (org.apache.avro.AvroMissingFieldException e) {
        throw e;
      } catch (java.lang.Exception e) {
        throw new org.apache.avro.AvroRuntimeException(e);
      }
    }
  }

  @SuppressWarnings("unchecked")
  private static final org.apache.avro.io.DatumWriter<Sale>
    WRITER$ = (org.apache.avro.io.DatumWriter<Sale>)MODEL$.createDatumWriter(SCHEMA$);

  @Override public void writeExternal(java.io.ObjectOutput out)
    throws java.io.IOException {
    WRITER$.write(this, SpecificData.getEncoder(out));
  }

  @SuppressWarnings("unchecked")
  private static final org.apache.avro.io.DatumReader<Sale>
    READER$ = (org.apache.avro.io.DatumReader<Sale>)MODEL$.createDatumReader(SCHEMA$);

  @Override public void readExternal(java.io.ObjectInput in)
    throws java.io.IOException {
    READER$.read(this, SpecificData.getDecoder(in));
  }

}










